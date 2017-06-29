use v6.c;

use Log::Any;
use Template::Mojo;

use Bailador::Configuration;
use Bailador::Commands;
use Bailador::ContentTypes;
use Bailador::Context;
use Bailador::Exceptions;
use Bailador::LogAdapter;
use Bailador::Route;
use Bailador::Sessions;
use Bailador::Template::Mojo;


class Bailador::App is Bailador::Route {
    has Str $.location is rw = '.';
    has Bailador::ContentTypes $.content-types = Bailador::ContentTypes.new;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions $!sessions;
    has Bailador::Configuration $.config = Bailador::Configuration.new;
    has Bailador::Commands $.commands = Bailador::Commands.new;
    has Bailador::LogAdapter $.log-adapter = Bailador::LogAdapter.new;

    submethod TWEAK {
        self.load-config();
    }

    method load-config {
        $!config.load-from-file($!location.IO);
        $!config.load-from-env();
    }

    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, Str :$layout, *@params, *%params) {
        my $content = $!renderer.render("$.location/" ~ self.config.views ~ "/$tmpl", |@params, |%params);

        my $use-this-layout = $layout // $.config.layout;
        if $use-this-layout {
            my $filename;
            for ('', '.tt', '.mustache', '.html', '.template') -> $ext {
                $filename = "$.location/layout/$use-this-layout" ~ $ext;
                return $!renderer.render($filename, $content) if $filename.IO.e
            }
        }

        return $content;
    }

    method before-run() {
        # probably a good place for a hook
        my $formatter = $.config.log-format;
        my @filter    = $.config.log-filter;
        Log::Any.add($.log-adapter, :$formatter, :@filter);
    }

    multi method render($result) {
        if $result ~~ IO::Path {
            my $type = $.content-types.detect-type($result);
            self.render: content => $result.slurp(:bin), :$type;
        }
        else {
            self.render(content => $result);
        }
    }

    multi method render(Int :$status = 200, Str :$type, :$content!) {
        $.context.autorender = False;
        self.response.code = $status;
        self.response.headers<Content-Type> = $type if $type;
        self.response.content = $content;
    }

    multi method redirect(Str $location, Int :$code = 302) {
        $.context.autorender = False;
        self.response.code = $code;
        self.response.headers<Location> = $location;
    }

    method !sessions() {
        unless $!sessions.defined {
            $!sessions = Bailador::Sessions.new(:$!config);
        }
        return $!sessions;
    }

    method session() {
        self!sessions.load(self.request);
    }

    method session-delete() {
        self!sessions.delete-session(self.request);
    }

    method !done-rendering() {
        # store session according to session engine
        # good place for a Hook
        self!sessions.store(self.response, self.request.env);
    }

    multi method baile() {
        my $command;
        if $.config.default-command() {
            $command = $.config.default-command();
        } elsif $.config.command-detection() {
            $command = $.commands.detect-command();
        } else {
            die 'can not detect command';
        }
        self.baile($command);
    }

    multi method baile(Str $command, *@args) {
        my $cmd = $.commands.get-command($command);
        $.config.load-from-args(@args),
        $.before-run();
        $cmd.run(app => self );
    }

    method get-psgi-app {
        # quotes from https://github.com/zostay/P6SGI
        # draft 0.7
        # * A P6SGI application is a Perl 6 routine that expects to receive an environment from an application server and returns a response each time it is called by the server.
        # * An application MUST return a Promise
        # * The message payload MUST be a sane Supply or an object that coerces into a sane Supply.
        return sub (%env) {
            start {
                self.dispatch(%env).psgi;
            }
        }
    }

    method !adjust-log-adapter($env) {
        if ($env<p6w.errors>:exists) {
            self.log-adapter.io-handle = $env<p6w.errors>;
        } else {
            # this should never happen
            self.log-adapter.io-handle = $*ERR;
        }
    }

    method dispatch($env) {
        self.context.env = $env;
        try {
            self!adjust-log-adapter($env),
            my $method = $env<REQUEST_METHOD>;
            my $uri    = $env<PATH_INFO> // $env<REQUEST_URI>.split('?')[0];
            my $result = self.recurse-on-routes($method, $uri);

            if $.context.autorender {
                if $result.defined {
                    self.render: $result;
                }
                else {
                    die X::Bailador::ControllerReturnedNoResult.new(:$method, :$uri);
                }
            }

            LEAVE {
                my $http-code = self.response.code;
                Log::Any.trace("Serving $method $uri with $http-code");
                self!done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.render(content => Any);
                }
                when X::Bailador::NoRouteFound {
                    Log::Any.notice("No Route was Found for $method $uri");
                    if $!location.defined && "$!location/views/404.xx".IO.e {
                        self.render(:status(404), :type<text/html;charset=UTF-8>, content => self.template("404.xx", []));
                    } else {
                        self.render(:status(404), :type<text/plain;charset=UTF-8>, content => 'Not found');
                    }
                }
                default {
                    Log::Any.error(.gist);
                    #if ($env<p6w.errors>:exists) {
                    #    my $err = $env<p6w.errors>;
                    #    #$err.say(.gist);
                    #}
                    #else {
                    #    note .gist;
                    #}

                    my $err-page;
                    if $!config.mode eq 'development' {
                        state $error-template = Template::Mojo.new(%?RESOURCES<error.template>.IO.slurp);
                        $err-page = $error-template.render($_, self.request());
                        self.render(status => 500, type => 'text/html;charset=UTF-8', content => $err-page);
                    } elsif $!location.defined && "$!location/views/500.xx".IO.e {
                        self.render(:status(500), :type<text/html;charset=UTF-8>, content => self.template("500.xx", []));
                    } else {
                        self.render(:status(500), :type<text/plain;charset=UTF-8>, content => 'Internal Server Error');
                    }
                }
            }
        }

        return self.response;
    }

    method curry(Str:D $method, *@args) {
        die "Method $method not found on class " ~ self.WHAT.gist unless self.^method_table{$method}:exists;
        return self.^method_table{$method}.assuming(self, |@args);
    }
}
