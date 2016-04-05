use Bailador::Request;
use Bailador::Context;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Sessions::Config;

class Bailador::App {
    has %.routes  = GET => [], 'POST' => [];
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

    multi method find_route(Bailador::Request $req) {
        self._find_route: $req.method, $req.path
    }

    # a simplier version to avoid creation of short-living objects
    multi method find_route($env) {
        self._find_route: $env<REQUEST_METHOD>, $env<PATH_INFO>
    }

    method _find_route($meth, $uri) {
        for %.routes{$meth}.list -> $r {
            next unless $r;
            if $uri ~~ $r.key {
                return $r, $/;
            }
        }
        return;
    }

    method add_route($meth, Pair $route) {
        %.routes{$meth}.push: $route;
    }

    method session() {
        unless $!sessions.defined {
            $!sessions = Bailador::Sessions.new(:$.sessions-config);
        }
        $!sessions.load(self.request);
    }

    method done-rendering() {
        # store session according to session engine
        $!sessions.store(self.response, self.request.env);
    }
}
