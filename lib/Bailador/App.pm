use Bailador::Context;
use Bailador::Route;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Sessions::Config;
use Bailador::Exceptions;

class Bailador::App does Bailador::Routing {
    has Str $.location is rw;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions::Config $.sessions-config = Bailador::Sessions::Config.new;
    has Bailador::Sessions $!sessions;

    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, *@params) {
        $!renderer.render(slurp("$.location/views/$tmpl"), @params);
    }

    method render($result) {
        $.context.autorender = False;
        self.response.code = 200;
        self.response.content = $result;
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
            my $result = self.recurse-on-routes($env);
            self.render: $result if $.context.autorender;

            LEAVE {
                self.done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.response.code = 200;
                    self.response.headers<Content-Type> = 'text/html';
                    self.response.content = Any;
                }
                when X::Bailador::NoRouteFound {
                    self.response.code = 404;
                    self.response.headers<Content-Type> = 'text/html';
                    self.response.content = 'Not found';
                }
                default {
                    my $err = $env<p6sgi.version>:exists ?? $env<p6sgi.errors> !! $env<p6sgi.errors>;
                    $err.say(.gist);
                    .gist.say;
                    self.response.code = 500;
                    self.response.headers<Content-Type> = 'text/plain';
                    self.response.content = 'Internal Server Error';
                }
            }
        }

        return self.response;
    }
}
