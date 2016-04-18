use v6;

use Bailador::Request;

class Bailador::Route { ... }

role Bailador::Routing {
    has Bailador::Route @.routes;
    multi method find_route(Bailador::Request $req) {
        self._find_route: $req.method, $req.path
    }

    # a simplier version to avoid creation of short-living objects
    multi method find_route($env) {
        self._find_route: $env<REQUEST_METHOD>, $env<PATH_INFO>
    }

    method _find_route($meth, $uri) {
        for @.routes -> $r {
            if $r.match: $meth, $uri -> $match {
                return ($r, $match);
            }
        }
        return False;
    }


    multi method add_route(Bailador::Route $route) {
        @.routes.push($route);
    }

    multi method add_route(Str $method, Pair $x) {
        my $route = Bailador::Route.new($method, $x);
        @.routes.push($route);
    }

    ## syntactic sugar!
    method get(Pair $x) {
        self.add_route: 'GET', $x;
        return $x;
    }

    method post(Pair $x) {
        self.add_route: 'POST', $x;
        return $x;
    }

    method put(Pair $x) {
        self.add_route: 'PUT', $x;
        return $x;
    }

    method delete(Pair $x) {
        self.add_route: 'DELETE', $x;
        return $x;
    }
}

class Bailador::Route does Bailador::Routing {
    subset HttpMethod of Str where {$_ eq any <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT> }
    has HttpMethod $.method;
    has Regex $.path is required;
    has Callable $.code is required;

    sub route_to_regex($route) {
        $route.split('/').map({
            my $r = $_;
            if $_.substr(0, 1) eq ':' {
               $r = q{(<-[\/\.]>+)};
            }
            $r
        }).join("'/'");
    }

    multi method new(Str $method, Str $path, Callable $code) {
        my $regex = "/ ^ " ~ route_to_regex($path) ~ " \$ /";
        self.bless(:$method, path => $regex.EVAL, :$code);
    }
    multi method new(Str $method, Regex $path, Callable $code) {
        self.bless(:$method, :$path, :$code);
    }
    multi method new($meth, Pair $route) {
        self.new($meth, $route.key, $route.value);
    }

    method match (Str $method, Str $path) {
        if $.method {
            return False if $.method ne $method
        }
        return $path ~~ $.path;
    }
}
