use v6.c;

use HTTP::Easy::PSGI;
use JSON::Fast;

use Bailador::App;
use Bailador::Request;
use Bailador::RouteHelper;
use Bailador::Template;

unit module Bailador:ver<0.0.11>:auth<github:Bailador>;

my $app;

my package EXPORT::DEFAULT {
    OUR::{'&to-json'} := &to-json;
}

multi sub app {
    unless $app {
        $app = Bailador::App.new;
    }
    return $app;
}

multi sub app(Bailador::App $myapp) is export {
    $app = $myapp;
}

sub error(Pair $x) is export {
    app.add_error: $x;
    return $x;
}

sub use-feature(Str $feature-name) is export {
    my $feature = 'Bailador::Feature::' ~ $feature-name;
    require ::($feature);
    app() does ::($feature);
}

sub get(Pair $x) is export {
    app.add_route: make-route('GET', $x);
    return $x;
}

sub post(Pair $x) is export {
    app.add_route: make-route('POST', $x);
    return $x;
}

sub put(Pair $x) is export {
    app.add_route: make-route('PUT', $x);
    return $x;
}

sub delete(Pair $x) is export {
    app.add_route: make-route('DELETE', $x);
    return $x;
}

sub patch(Pair $x) is export {
    app.add_route: make-route('PATCH', $x);
    return $x;
}

sub head(Pair $x) is export {
    app.add_route: make-route('HEAD', $x);
    return $x;
}

sub static-dir(Pair $x) is export {
    app.add_route: make-static-dir-route($x, app);
}

sub prefix(Pair $x) is export {
    my $route = make-prefix-route($x.key);
    app.prefix($route, $x.value);
}

sub prefix-enter(Callable $code) is export {
    app.prefix-enter($code);
}

sub request is export { $app.context.request }

sub content_type(Str $type) is export {
    app.response.headers<Content-Type> = $type;
}

sub header(Str $name, Cool $value) is export {
    app.response.headers{$name} = ~$value;
}

our sub cookie(Str $name, Str $value, Str :$domain, Str :$path,
        DateTime :$expires, Bool :$http-only; Bool :$secure) is export {
    app.response.cookie($name, $value, :$domain, :$path, :$expires, :$http-only, :$secure);
}

sub status(Int $code) is export {
    app.response.code = $code;
}

sub template(Str $tmpl, *@params, *%params) is export {
    app.template($tmpl, @params, |%params);
}

sub session is export {
    return app.session();
}

sub session-delete is export {
    return app.session-delete();
}

sub uri-for(Str $path) is export {
    return app.request.uri-for($path);
}

sub renderer(Bailador::Template $renderer) is export {
    app.renderer = $renderer;
}

multi sub render(*%param) is export {
    app.render(|%param);
}

multi sub render($content) is export {
    app.render(:$content);
}

sub get-psgi-app() is export {
    return app.get-psgi-app();
}

sub redirect(Str $location, Int $code = 302) is export {
    app.redirect($location, $code);
}

# for Dancer2 compatibility
sub set(Str $key, $value) is export {
    app.config.set($key, $value);
}

sub config() is export {
    return app.config;
}

sub add-command-ns(Str:D $namespace) is export {
    app.commands.add-ns($namespace);
}

sub baile(*%param, *@param) is export {
    app.baile(|%param, |@param);
}
