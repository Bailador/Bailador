use v6.c;

use HTTP::Status;
use Log::Any:ver('0.9.4');
use Template::Mojo;
use URI; # Used to parse log configuration
use URI::Encode;

use Bailador::Commands;
use Bailador::Configuration;
use Bailador::ContentTypes;
use Bailador::Context;
use Bailador::Exceptions;
use Bailador::Log::Adapter;
use Bailador::Log::Formatter;
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
    has Bailador::Log::Adapter $.log-adapter = Bailador::Log::Adapter.new;
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

    method !templatefile-extentions(Str:D $file) {
        for ('', '.tt', '.mustache', '.html', '.template') -> $ext {
            my $filename = $file ~ $ext;
            return $filename if $filename.IO.e;
        }
        Log::Any.error("template file not found: $file");
        return Str:U;
    }

    method template(Str $tmpl, Str :$layout, *@params, *%params) {
        my $content = "";
        my $content-template = self!templatefile-extentions($.location.IO.child(self.config.views).child($tmpl).Str);
        $content = $!renderer.render($content-template, |@params, |%params) if $content-template;

        my $use-this-layout = $layout // $.config.layout;
        if $use-this-layout {
            my $layout-template = self!templatefile-extentions($.location.IO.child('layout').child($use-this-layout).Str);
            if $layout-template {
                Log::Any.debug("Rendering with layout $use-this-layout");
                $content = $!renderer.render($layout-template, $content);;
            }
        } else {
            Log::Any.debug("Rendering without a layout");
        }

        return $content;
    }

    method render-file(Str:D $filename is copy, Str :$mime-type) {
        # The supplied path in $filename should be relative to our root. By default directory traversal
        # is disabled because security, so basically only relavite paths from our applications location
        # is possible. The file is rendered and served by this method.
        $filename = $.location.IO.child($filename).resolve.Str;

        if (!$filename.starts-with($.location)) {
            # File is outside our $.location
            Log::Any.error("Serving file outside of root is denied: " ~ $filename);
            return;
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
            die "cannot set location, it is already defined. Set it before you add the first route";
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
            if $*DISTRO.is-win {
                $app-root.=subst(/\\/, '', :x(1));
            }
            self.location($app-root.Str);
        }
        return $!location;
    }

    method before-run() {
        # probably a good place for a hook

        # Configure logging system
        use Bailador::Log;
        init( config => self.config, p6w-adapter => self.log-adapter );

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
        my $env = self.context.env;
        my $severity = 'error';
        given $http-code {
            when is-success($_)      { $severity = 'info';   }
            when is-redirect($_)     { $severity = 'debug';  }
            when is-client-error($_) { $severity = 'notice'; }
            when is-server-error($_) { $severity = 'error';  }
            # default                  { $severity = 'error';  }
        }
        # The message argument is only used in default logging format
        Log::Any.log(
            :msg("Serving $method $uri with $http-code in " ~ $end - $start ~ 's'),
            :severity( $severity ),
            :extra-fields( Hash.new( ( $env.kv, :HTTP_CODE(self.response.code) ) ) ),
            :category('request')
        );
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
            die 'cannot detect command';
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

    multi method baile(Int $port, *@args) {
        die qq:to/ERROR/;
        baile is no longer called with the port as only argument.
        Please call baile without arguments and put this line in front:

            config.port      = $port;

        For more information, please see the Configuration section
        of the Bailador manual:

            https://github.com/Bailador/Bailador/blob/dev/doc/README.md#configuration
        ERROR
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
            my $uri    = uri_decode( $env<PATH_INFO> // $env<REQUEST_URI>.split('?')[0] );
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
                    Log::Any.warning("nothing to render, looks suspicious");
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
                    Log::Any.error(
                      .gist,
                      :category( 'request-error' ),
                      :extra-fields( Hash.new( ( $env.kv, :file-and-line($?FILE~':'~$?LINE), :pid($*PID), :client-ip('-') ) ) ),
                    );

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
