use v6.c;

use Bailador::Route;

role Bailador::Feature::AutoHead {

    method before-run(|c) {
        generate-head-routes(self);
        nextsame();
    }

    multi sub generate-head-routes($app) { generate-head-routes($app, $app); }
    multi sub generate-head-routes($route, $app) {

        my %found-head;
        my %found-get;

        for $route.routes -> $child-route {
            generate-head-routes($child-route);

            if 'GET' ~~ any( $child-route.method ) && 'HEAD' !~~ any ( $child-route.method ) {
                # found a route with GET but no HEAD
                %found-get{ $child-route.path.perl } = $child-route;
            }
            if 'HEAD' ~~ any( $child-route.method ) && 'GET' !~~ any ( $child-route.method ) {
                # found a route with HEAD but no GET
                %found-head{ $child-route.path.perl } = 1;
            }
        }

        for %found-get.kv -> $key, $orig-route {
            unless %found-head{ $key }:exists {
                my $code       = sub (|c) {
                    $orig-route.code.(|c);
                    $app.render: "";
                };
                my $path-str   = $orig-route.path-str;
                my $path       = $orig-route.path;
                my $head-route = Bailador::Route.new('HEAD', $path, $code, $path-str);
                $route.add_route($head-route);
            }
        }
    }
}
