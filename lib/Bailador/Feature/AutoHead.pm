use v6.c;

use Bailador::Route::AutoHead;
use Bailador::RouteHelper;

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
            generate-head-routes($child-route, $app);

            if 'GET' ~~ any( $child-route.method ) && 'HEAD' !~~ any ( $child-route.method ) {
                # found a route with GET but no HEAD
                %found-get{ $child-route.route-spec } = $child-route;
            }
            if 'HEAD' ~~ any( $child-route.method ) && 'GET' !~~ any ( $child-route.method ) {
                # found a route with HEAD but no GET
                %found-head{ $child-route.route-spec } = 1;
            }
        }

        for %found-get.kv -> $key, $orig-route {
            unless %found-head{ $key }:exists {
                my $code       = sub (Match $match) {
                    my $result = $orig-route.execute($match);
                    # this turns off auto rendering
                    $app.render: "";
                    # return the old result, because if boolean this is important for route dispatching
                    return $result;
                };
                my $path       = $orig-route.url-matcher;
                my $head-route = Bailador::Route::AutoHead.new( methods => 'HEAD', url-matcher => $path, code => $code);
                $route.add_route($head-route);
            }
        }
    }
}
