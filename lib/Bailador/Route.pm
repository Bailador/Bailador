use v6;

use Bailador::Request;
use Bailador::Exceptions;

class Bailador::Route {
    subset HttpMethod of Str where {$_ eq any <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH> }
    has HttpMethod @.method;
    has Regex $.path;
    has Callable $.code is rw;
    has Bailador::Route @.routes;
    has Bailador::Route $!prefix-route;

    method !get-prefix-route {
        return $!prefix-route
    }
    method !set-prefix-route(Bailador::Route $prefix-route) {
        $!prefix-route = $prefix-route;
    }

    sub route_to_regex($route) {
        $route.split('/').map({
            my $r = $_;
            if $_.substr(0, 1) eq ':' {
               $r = q{(<-[\/\.]>+)};
            }
            $r
        }).join("'/'");
    }

    multi submethod new(Str @method, Regex $path, Callable $code) {
        self.bless(:@method, :$path, :$code);
    }
    multi submethod new(Str $method, Regex $path, Callable $code) {
        my Str @methods = $method eq 'ANY'
        ?? <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH>
        !! ($method);
        self.new(@methods, $path, $code);
    }
    multi submethod new(Str $method, Str $path, Callable $code) {
        my $regex = "/ ^ " ~ route_to_regex($path) ~ " [ \$ || <?before '/' > ] /";
        self.new($method, $regex.EVAL, $code);
    }
    multi submethod new($meth, Pair $route) {
        self.new($meth, $route.key, $route.value);
    }

    method !match (Str $method, Str $path) {
        if @.method {
            return False if @.method.any ne $method
        }
        return $path ~~ $.path;
    }

    method recurse-on-routes(Str $method, Str $uri) {
        for @.routes -> $r {
            if $r!match: $method, $uri -> $match {
                my @params = $match.list;
                my $result = $r.code.(|@params);

                if $result ~~ Failure {
                    $result.exception.throw;
                }
                elsif $result eqv True {
                    try {
                        # work around a bug in perl6
                        # https://github.com/rakudo/rakudo/commit/c04b8b5cc9
                        # <moritz> ufobat: fix pushed
                        my $postmatch =
                            $match.to == $match.from ??
                            $uri.substr($match.to) !!
                            $match.postmatch;
                        return $r.recurse-on-routes($method, $postmatch);
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

    multi method prefix(Str $prefix, Callable $code) {
        my $curr = self!get_current_route();
        $curr!set-prefix-route( Bailador::Route.new('ANY', $prefix, sub { True }) );
        $code.();
        self!del_current_route();
    }

    method !del_current_route {
        if not $!prefix-route {
            # nothing to do
        }
        elsif $!prefix-route and not $!prefix-route!get-prefix-route {
            my $route = $!prefix-route;
            $!prefix-route = Bailador::Route:U;
            self.add_route($route);
        }
        else {
            $!prefix-route!del_current_route()
        }
    }
    method !get_current_route {
        return $!prefix-route!get_current_route() if $!prefix-route;
        return self;
    }

    method prefix-enter(Callable $code) {
        my $curr = self!get_current_route();
        $curr.code = $code;
    }

    multi method add_route(Bailador::Route $route) {
        my $curr = self!get_current_route();
        $curr.routes.push($route);
    }

    multi method add_route(Str $method, Pair $x) {
        my $route = Bailador::Route.new($method, $x);
        self.add_route($route);
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

    multi method prefix(Pair $x){
        self.prefix($x.key, $x.value);
    }
}
