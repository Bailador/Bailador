use Bailador::Context;
use Bailador::Route;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Sessions::Config;

class Bailador::App does Bailador::Routing {
    my $_location;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions::Config $.sessions-config = Bailador::Sessions::Config.new;
    has Bailador::Sessions $!sessions;

    method request  { $.context.request  }
    method response { $.context.response }
    method location is rw { return-rw $_location }
    method template(Str $tmpl, @params) {
        $!renderer.render(slurp("$_location/views/$tmpl"), @params);
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
        my ($r, $match) = self.find_route($env);

        if $r {
            try {
                self.response.code = 200;
                my @params = $match.list
                    if $match;
                self.response.content = $r.code.(|@params);

                self.done-rendering();
                CATCH {
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
        }

        return self.response;
    }
}
