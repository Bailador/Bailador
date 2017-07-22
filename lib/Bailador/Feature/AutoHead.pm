use v6.c;

use Bailador::Route::AutoHead;
use Bailador::RouteHelper;

role Bailador::Feature::AutoHead is DEPRECATED {
    #method before-run(|c) {
    #    generate-head-routes(self);
    #}
}
