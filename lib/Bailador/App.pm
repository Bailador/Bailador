use v6.c;

use Log::Any;
use Template::Mojo;

use Bailador::Commands;
use Bailador::Configuration;
use Bailador::ContentTypes;
use Bailador::Context;
use Bailador::Exceptions;
use Bailador::LogAdapter;
use Bailador::LogFormatter;
use Bailador::Route;
use Bailador::Route::AutoHead;
use Bailador::Sessions;
use Bailador::Template::Mojo;

class Bailador::App does Bailador::Routing {
    # has Str $.location is rw = get-app-root().absolute;
    has Str $!location;
    has Bool $!started = False;
    has Bailador::ContentTypes $.content-types = Bailador::ContentTypes.new;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions $!sessions;
    has Bailador::Configuration $.config = Bailador::Configuration.new;
    has Bailador::Commands $.commands = Bailador::Commands.new;
    has Bailador::LogAdapter $.log-adapter = Bailador::LogAdapter.new;
    has %.error_handlers;

    method load-config {
        if %*ENV<BAILADOR_CONFIGDIR> {
            $!config.config-dir = %*ENV<BAILADOR_CONFIGDIR>;
        }
        if %*ENV<BAILADOR_CONFIGFILE> {
            $!config.config-file = %*ENV<BAILADOR_CONFIGFILE>;
        }
        $!config.load-from-dir($.location);
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

    method render-file(Str:D $filename is copy, Str :$mime-type) {
        # The supplied path in $filename should be relative to our root. By default directory traversal
        # is disabled because security, so basically only relavite paths from our applications location
        # is possible. The file is rendered and served by this method.
        $filename = $filename.IO.resolve.Str;

        if (!$filename.starts-with($.location)) {
            # File is outside our $.location
            Log::Any.error("Serving file outside of root is denied: " ~ $filename);
            #return;
        }

        if ($filename.IO.e) {
            if ($mime-type.defined) {
                self.render(status => 200, type => $mime-type, content => $filename.IO);
            }
            else {
                # Content type auto-detection via render()
                self.render(status => 200, content => $filename.IO);
            }
        }
        else {
            Log::Any.error("File not found! " ~ $filename);
        }
    }

    method before-add-routes() {
        # this is a good place for a hook
        self.load-config();
    }

    # do not use $!location outside of this subs
    multi method location(Str $location) {
        if $!location.defined {
            die "can not set location, it is already defined. Set it before you add the first route";
        }
        $!location = $location;

        # call after $!location is defined
        self.before-add-routes();
    }
    multi method location() {
        unless $!location.defined {
            my $app-root;
            if %*ENV<BAILADOR_APP_ROOT>:exists {
                $app-root = %*ENV<BAILADOR_APP_ROOT>.IO.resolve;
            } else {
                my $parent = $*PROGRAM.parent.resolve;
                $app-root = $parent.basename eq 'bin' ?? $parent.parent !! $parent;
            }
            self.location($app-root.Str);
        }
        return $!location;
    }

    method before-run() {
        # probably a good place for a hook
        my @filter    = $.config.log-filter;
        my $formatter = Bailador::LogFormatter.new(
            format   => $.config.log-format,
            colorize => $.config.terminal-color,
            colors   => {
                trace     =>  $.config.terminal-color-trace,
                debug     =>  $.config.terminal-color-debug,
                info      =>  $.config.terminal-color-info,
                notice    =>  $.config.terminal-color-notice,
                warning   =>  $.config.terminal-color-warning,
                errors    =>  $.config.terminal-color-error,
                critical  =>  $.config.terminal-color-critical,
                alert     =>  $.config.terminal-color-alert,
                emergency =>  $.config.terminal-color-emergency,
            },
        );
        # https://github.com/jsimonet/log-any/issues/1
        # black magic to increase the logging speed
        Log::Any.add( Log::Any::Pipeline.new(), :overwrite );
        Log::Any.add($.log-adapter, :$formatter, :@filter);

        self!generate-head-routes(self);
    }

    method !generate-head-routes(Bailador::Routing $route) {

        my %found-head;
        my %found-get;

        for $route.routes -> $child-route {
            self!generate-head-routes($child-route);

            if 'GET' ~~ any( $child-route.method ) && 'HEAD' !~~ any ( $child-route.method ) {
                # found a route with GET but no HEAD
                %found-get{ $child-route.route-spec } = $child-route;
            }
            if 'HEAD' ~~ any( $child-route.method ) && 'GET' !~~ any ( $child-route.method ) {
                # found a route with HEAD but no GET
                %found-head{ $child-route.route-spec } = 1;
            }
        }

        for %found-get.kv -> $key, $orig-route {
            unless %found-head{ $key }:exists {
                my $code       = sub (Match $match) {
                    my $result = $orig-route.execute($match);
                    if $result ~~ Bool {
                        # no need to render for a route that defines access
                        return $result;
                    }
                    if $.context.autorender {
                        # no rendering happend so far
                        self.render();
                    } else {
                        # rendering happend so far
                        # keep statuscode, content-type but discard content
                        self.render(
                            status  => self.response.code,
                            type    => self.response.headers<Content-Type> // '',
                        );
                    }
                    # return the old result, because if boolean this is important for route dispatching
                    return $result;
                };
                my $path       = $orig-route.url-matcher;
                my $head-route = Bailador::Route::AutoHead.new( method => 'HEAD', url-matcher => $path, code => $code);
                $route.add_route($head-route);
            }
        }
    }

    multi method render($content) {
        self.render( content => $content );
    }

    multi method render(Int :$status, Str :$type is copy, :$content is copy) {

        # already set type manually, this type always wins
        $type = self.response.headers<Content-Type> if ! $type.defined and self.response.headers<Content-Type>:exists;
        if $content ~~ IO::Path {
            my $fallback = self.config.file-discovery-content-type;
            my $detected = $.content-types.detect-type($content, $fallback);
            $type        = $detected if !$type.defined and $detected;
            $content     = $content.slurp(:bin);
        }

        $type = self.config.default-content-type unless $type.defined;

        # set values
        $.context.autorender = False;
        self.response.code = $status                if $status;
        self.response.headers<Content-Type> = $type if $type; # and $content.defined maybe?
        self.response.content = $content            if $content.defined;
    }

    method redirect(Str $location, Int $status = 302) {
        self.response.headers<Location> = $location;
        self.render(:$status, content => '', type => '');
        # $.context.autorender = False;
        # self.response.code = $code;
    }

    method add_error(Pair $x) {
        self.error_handlers{$x.key} = $x.value;
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

    method log-request(DateTime $start, DateTime $end, Str $method, Str $uri, Int $http-code) {
        my $message = "Serving $method $uri with $http-code in " ~ $end - $start ~ 's';
        given $http-code {
            when 200 <= * < 300 {
                Log::Any.info($message);
            }
            when 300 <= * < 400 {
                Log::Any.debug($message);
            }
            when 400 <= * < 500 {
                Log::Any.notice($message);
            }
            when * < 500 {
                Log::Any.error($message);
            }
            default {
                Log::Any.error($message);
            }
        }
    }

    multi method baile() {
        # initialize the location if we didnt need it so far. that reads the config
        $.location();

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
        # initialize the location if we didnt need it so far. that reads the config
        # in case we dont call baile() without parameters
        $.location();

        $.config.load-from-args(@args);
        my $cmd = $.commands.get-command($command);

        die 'can only baile once' if $!started;
        $!started = True;

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
        my DateTime $start = DateTime.now;
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
                my DateTime $end = DateTime.now;
                self.log-request($start, $end, $method, $uri, $http-code);
                self!done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.render();
                }
                when X::Bailador::NoRouteFound {
                    if self.error_handlers{404} {
                        self.render(:status(404), :type<text/html;charset=UTF-8>, content => self.error_handlers{404}());
                    } elsif $.location.defined && "$.location/views/404.xx".IO.e {
                        self.render(:status(404), :type<text/html;charset=UTF-8>, content => self.template("404.xx", []));
                    } else {
                        self.render(:status(404), :type<text/plain;charset=UTF-8>, content => 'Not found');
                    }
                }
                default {
                    Log::Any.error(.gist);

                    my $err-page;
                    if $!config.mode eq 'development' {
                        state $error-template = Template::Mojo.new(%?RESOURCES<error.template>.IO.slurp);
                        $err-page = $error-template.render($_, self.request());
                        self.render(status => 500, type => 'text/html;charset=UTF-8', content => $err-page);
                    } elsif self.error_handlers{500} {
                        self.render(:status(500), :type<text/html;charset=UTF-8>, content => self.error_handlers{500}());
                    } elsif $.location.defined && "$.location/views/500.xx".IO.e {
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
