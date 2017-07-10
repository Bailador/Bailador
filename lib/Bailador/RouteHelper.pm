use v6.c;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::Prefix;
use Bailador::Route::Simple;
use Bailador::Route::StaticFile;

unit module Bailador::RouteHelper;

multi sub make-prefix-route($url-matcher) is export {
    my @method = <ANY>;
    Bailador::Route::Prefix.new( :@method, :$url-matcher );
}
multi sub make-prefix-route($url-matcher, Callable $prefix-enter-code) is export {
    my @method = <ANY>;
    Bailador::Route::Prefix.new( :@method, :$url-matcher, :$prefix-enter-code );
}

multi sub make-simple-route(Str $method, Pair $x) is export {
    Bailador::Route::Simple.new( :$method, url-matcher => $x.key, code => $x.value);
}

sub make-static-dir-route(Pair $x, Bailador::App $app) is export {
    my $path = $x.key;
    my IO $directory = $x.value ~~ IO ?? $x.value !! $app.location.IO.child($x.value.Str);
    return Bailador::Route::StaticFile.new(method => 'GET', url-matcher => $x.key, directory => $directory);
}

