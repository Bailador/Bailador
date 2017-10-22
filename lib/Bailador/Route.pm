use v6.c;

use Bailador::Exceptions;
use Bailador::Request;

role Bailador::Route { ... }

role Bailador::Routing {
    ## !! those two members are *actually* private, due to
    ## https://rt.perl.org/Public/Bug/Display.html?id=131707
    ## https://rt.perl.org/Public/Bug/Display.html?id=130690
    ## they can not be private :-(
    ## change that as soon as possible.
    ## has Bailador::Route $!prefix-route;
    has Bailador::Route @.routes;
    has Bailador::Route $.prefix-route is rw;

    ## Route Dispatch Stuff
    method recurse-on-routes(Str $method, Str $uri) {
        for @.routes -> $r {
            if $r.match: $method, $uri -> $match {
                my $result = $r.execute($match);

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
                        my $prematch = $match.prematch;
                        return $r.recurse-on-routes($method, $prematch ~ $postmatch);
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


    ## Add Routes#
    multi method add_route(Bailador::Route $route) {
        my $curr = self!get_current_route();
        # avoid obvious duplicate routes
        my $matches = $curr.routes.first({ $_.is-similar-to($route) });
        die "duplicate route: {$route.gist}" if $matches;
        $curr.routes.push($route);
    }

    ## Prefix Route Stuff
    method !get-prefix-route {
        return $.prefix-route
    }

    method !set-prefix-route(Bailador::Route $prefix-route) {
        $.prefix-route = $prefix-route;
    }

    method !del_current_route {
        if not $.prefix-route {
            # nothing to do
        }
        elsif $.prefix-route and not $.prefix-route!get-prefix-route {
            my $route = $.prefix-route;
            $.prefix-route = Bailador::Route:U;
            self.add_route($route);
        }
        else {
            $.prefix-route!del_current_route()
        }
    }
    method !get_current_route {
        return $.prefix-route!get_current_route() if $.prefix-route;
        return self;
    }

     method prefix(Bailador::Route $prefix, Callable $code) {
        my $curr = self!get_current_route();
        $curr!set-prefix-route( $prefix );
        $code.();
        self!del_current_route();
    }

    method prefix-enter(Callable $code) {
        my $curr = self!get_current_route();
        $curr.set-prefix-enter: $code;
    }
}

my Str @all-methods = <GET PUT POST HEAD PUT DELETE TRACE OPTIONS CONNECT PATCH>;
subset HttpMethod of Str where {$_ eq any(@all-methods) }
subset UrlMatcher where * ~~ Regex|Str;

role Bailador::Route does Bailador::Routing {
    has HttpMethod @.method is required;
    has UrlMatcher $.url-matcher is required;
    has Regex $.regex is rw;

    method execute(Match $match) { ... }
    method build-regex() { ... }

    submethod BUILD-ROLE(:$method, :$url-matcher) {
        @!method = 'ANY' ~~ any(@$method) ?? @all-methods !! $method;
        $!url-matcher = $url-matcher;
    }

    method match (Str $method, Str $path) {
        if @.method {
            return False if @.method.any ne $method
        }
        return self!url-matcher($path);
    }

    method !url-matcher(Str $path) {

        unless $.regex {
            if $.url-matcher ~~ Regex {
                $.regex = $.url-matcher;
            } else {
                $.regex = self.build-regex();
            }
        }

        my Match $match = $path ~~ $.regex;
        #say "path: ", $path, " with regex: ", $.regex, " -> ", $match;
        return $match;
    }

    method !get-regex-str {
        return $.url-matcher.split('/').map({
            my $r = $_;
            if $_.substr(0, 1) eq ':' {
                $r = q{(<-[\/\.]>+)};
            } elsif $r.chars > 0 {
                $r = "'" ~  $r ~ "'";
            }
            $r
        }).join("'/'");
    }

    method method-spec {
        set(@.method) eqv set(@all-methods) ?? 'ANY' !! @.method.Str;
    }
    method route-spec {
        $.url-matcher ~~ Str ??  $.url-matcher !! $.url-matcher.perl;
    }

    method is-similar-to(Bailador::Route $other) {
        my $r = @.method.Str eq $other.method.Str && $.route-spec eq $other.route-spec;
        # if $r {
        #     say "self:  ", self.gist;
        #     say "other: ", $other.gist;
        # }
        return $r;
    }
    method gist {
        self.method.Str ~ " " ~ self.route-spec ~ " (" ~ self.^name ~ ")";
    }
}
