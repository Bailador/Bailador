use Bailador::Context;
use Bailador::Route;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Sessions::Config;
use Bailador::Exceptions;
use Bailador::ContentTypes;

class Bailador::App does Bailador::Routing {
    has Str $.location is rw;
    has Bailador::ContentTypes $.content-types = Bailador::ContentTypes.new;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions::Config $.sessions-config = Bailador::Sessions::Config.new;
    has Bailador::Sessions $!sessions;


    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, *@params) {
        $!renderer.render(slurp("$.location/views/$tmpl"), @params);
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

    multi method render(Int :$status = 200, Str :$type = 'text/html', :$content!) {
        $.context.autorender = False;
        self.response.code = $status;
        self.response.headers<Content-Type> = $type;
        self.response.content = $content;
    }

    multi method redirect(Str $location, Int :$code = 302) {
        $.context.autorender = False;
        self.response.code = $code;
        self.response.headers<Location> = $location;
    }

    method !sessions() {
        unless $!sessions.defined {
            $!sessions = Bailador::Sessions.new(:$.sessions-config);
        }
        return $!sessions;
    }

    method session() {
        self!sessions.load(self.request);
    }

    method session-delete() {
        self!sessions.delete-session(self.request);
    }

    method done-rendering() {
        # store session according to session engine
        self!sessions.store(self.response, self.request.env);
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
                self.done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.render(content => Any);
                }
                when X::Bailador::NoRouteFound {
                    # render 404
                }
                default {
                    if ($env<p6sgi.errors>:exists) {
                        my $err = $env<p6sgi.errors>;
                        $err.say(.gist);
                    }
                    else {
                        note .gist;
                    }
                    self.render(status => 500, type => 'text/plain', content => 'Internal Server Error');
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
