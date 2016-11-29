use v6;

use Bailador::Request;
use Bailador::Exceptions;

class Bailador::Route { ... }

role Bailador::Routing {
    has Bailador::Route @.routes;
    has Str $!prefix;

    method recurse-on-routes(Str $method, Str $uri) {

        for @.routes -> $r {
            if $r.match: $method, $uri -> $match {
                my @params = $match.list
                    if $match;
                my $result = $r.code.(|@params);

                if $result ~~ Failure {
                    $result.exception.throw;
                }
                elsif $result eqv True {
                    try {
                        return $r.recurse-on-routes($method, $uri);
                        CATCH {
                            when X::Bailador::NoRouteFound {
                                # continue with the next route
                            }
                        }
                    }
                }
                elsif $result eqv False {
                    # continue with the next route
                }
                else {
                    return $result;
                }
            }
        }
        die X::Bailador::NoRouteFound.new;
    }

    multi method add_route(Bailador::Route $route) {
        @.routes.push($route);
    }

    multi method add_route(Str $method, Pair $x) {
        my $path;
        if $!prefix {
            $path = $!prefix ~ $x.key;
        } else {
            $path = $x.key;
        }

        my $route = Bailador::Route.new($method, $path, $x.value);
        @.routes.push($route);
    }

    multi method prefix(Str $new-prefix) {
        $!prefix = $new-prefix;
    }

    multi method noprefix {
        $!prefix = '';
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

    method patch(Pair $x) {
        self.add_route: 'PATCH', $x;
        return $x;
    }
}

class Bailador::Route does Bailador::Routing {
    subset HttpMethod of Str where {$_ eq any <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH> }
    has HttpMethod $.method;
    has Regex $.path is required;
    has Callable $.code is required is rw;

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
