use v6.c;

use Bailador::App;
use Bailador::Route;
use Bailador::Route::Controller;
use Bailador::Route::IoC;
use Bailador::Route::Prefix;
use Bailador::Route::Simple;
use Bailador::Route::StaticFile;

unit module Bailador::RouteHelper;
subset UrlMatcher where Str|Regex;

multi sub make-prefix-route($url-matcher) is export {
    my @method = <ANY>;
    Bailador::Route::Prefix.new( :@method, :$url-matcher );
}
multi sub make-prefix-route($url-matcher, Callable $prefix-enter-code) is export {
    my @method = <ANY>;
    Bailador::Route::Prefix.new( :@method, :$url-matcher, :$prefix-enter-code );
}

multi sub make-route(Str $method, Pair $x, :$container) is export {
    make-route($method, $x.key, |$x.value, :$container);
}
multi sub make-route(Str $method, UrlMatcher $url-matcher, Callable $code, *%param) is export {
    Bailador::Route::Simple.new( :$method, :$url-matcher, :$code);
}

multi sub make-route(Str $method, UrlMatcher $url-matcher, *%param) is export {
    die "no method specified with 'to'"           unless %param<to>;
    if (%param<class>:exists or %param<controller>:exists) {
        return Bailador::Route::Controller.new(:$method, :$url-matcher, |%param);
    } elsif %param<container> && %param<service> {
        return Bailador::Route::IoC.new(:$method, :$url-matcher, |%param);
    } else {
        die "there must be a 'class' or 'controller' or 'service' with an 'container'";
    }
}

sub make-simple-route(Str $method, Pair $x) is export {
}

sub make-static-dir-route(Pair $x, Bailador::App $app) is export {
    my $path = $x.key;
    my IO $directory = $x.value ~~ IO ?? $x.value !! $app.location.IO.child($x.value.Str);
    return Bailador::Route::StaticFile.new(method => 'GET', url-matcher => $x.key, directory => $directory);
}

