use v6;

use Bailador::Context;
use Bailador::Route;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Exceptions;
use Bailador::ContentTypes;
use Bailador::Configuration;
use Template::Mojo;

class Bailador::App is Bailador::Route {
    has Str $.location is rw = '.';
    has Bailador::ContentTypes $.content-types = Bailador::ContentTypes.new;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions $!sessions;
    has Bailador::Configuration $.config = Bailador::Configuration.new;

    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, Str :$layout, *@params, *%params) {
        my $content = $!renderer.render("$.location/views/$tmpl", |@params, |%params);

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
        self!sessions.store(self.response, self.request.env);
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

    method dispatch($env) {
        self.context.env = $env;
        try {
            my $method = $env<REQUEST_METHOD>;
            my $uri    = $env<PATH_INFO>;
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
                self!done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.render(content => Any);
                }
                when X::Bailador::NoRouteFound {
                    my $err-page;
                    if $!location.defined {
                        $err-page = "$!location/views/404.xx".IO.e ?? self.template("404.xx", []) !! 'Not found';
                    } else {
                        $err-page = 'Not found';
                    }
                    self.render(status => 404, type => 'text/html, charset=utf-8', content => $err-page);
                }
                default {
                    if ($env<p6w.errors>:exists) {
                        my $err = $env<p6w.errors>;
                        $err.say(.gist);
                    }
                    else {
                        note .gist;
                    }

                    my $err-page;
                    if $!config.mode eq 'development' {
                        state $error-template = Template::Mojo.new(%?RESOURCES<error.template>.IO.slurp);
                        $err-page = $error-template.render($_, self.request());
                    } elsif $!location.defined {
                        $err-page = "$!location/views/500.xx".IO.e ?? self.template("500.xx", []) !! 'Internal Server Error';
                    } else {
                        $err-page = 'Internal Server Error';
                    }
                    self.render(status => 500, type => 'text/html, charset=utf-8', content => $err-page);
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
