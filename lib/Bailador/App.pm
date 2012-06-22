use Bailador::Request;
use Bailador::Context;
use Template::Mojo;

class Bailador::App {
    has %.routes  = { GET => [], 'POST' => [] };
    has $.location is rw;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Template::Mojo     $!template; # type object

    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, @params) {
        $!template.new(slurp "$!location/views/$tmpl").render(|@params);
    }

    my $current = Bailador::App.new;

    method set-current(Bailador::App $app) { $current = $app }
    method current                         { $current        }

    multi method find_route(Bailador::Request $req) {
        self._find_route: $req.method, $req.request_uri
    }

    # a simplier version to avoid creation of short-living objects
    multi method find_route($env) {
        self._find_route: $env<REQUEST_METHOD>, $env<REQUEST_URI>
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
}
