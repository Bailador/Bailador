use Bailador::Request;
use Bailador::Context;
use Bailador::Template::Mojo;

class Bailador::App {
    has %.routes  = GET => [], 'POST' => [];
    my $_location;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $!renderer = Bailador::Template::Mojo.new;

    method request  { $.context.request  }
    method response { $.context.response }
    method location is rw { return-rw $_location }
    method template(Str $tmpl, @params) {
        $!renderer.render(slurp("$_location/views/$tmpl"), @params);
    }

    my $current = Bailador::App.new;

    method set-current(Bailador::App $app) { $current = $app }
    method current                         { $current        }

    multi method find_route(Bailador::Request $req) {
        self._find_route: $req.method, $req.path
    }

    # a simplier version to avoid creation of short-living objects
    multi method find_route($env) {
        self._find_route: $env<REQUEST_METHOD>, $env<PATH_INFO>
    }

    method _find_route($meth, $uri) {
        for $current.routes{$meth}.list -> $r {
            next unless $r;
            if $uri ~~ $r.key {
                return $r, $/;
            }
        }
        return;
    }

    method add_route($meth, Pair $route) {
        $current.routes{$meth}.push: $route;
    }
}
