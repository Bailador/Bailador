use Bailador::App;
use Bailador::Request;
use Bailador::Template;
use HTTP::Easy::PSGI;

unit module Bailador;

my $app;

multi sub app {
    $app = Bailador::App.new unless $app;
    return $app;
}

multi sub app(Bailador::App $myapp) is export {
    $app = $myapp;
}

our sub import {
    app.location = callframe(1).file.IO.dirname;
}

sub get(Pair $x) is export {
    app.add_route: 'GET', $x;
    return $x;
}

sub post(Pair $x) is export {
    app.add_route: 'POST', $x;
    return $x;
}

sub put(Pair $x) is export {
    app.add_route: 'PUT', $x;
    return $x;
}

sub delete(Pair $x) is export {
    app.add_route: 'DELETE', $x;
    return $x;
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

sub sessions-config is export {
    return app.sessions-config;
}

sub renderer(Bailador::Template $renderer) is export {
    app.renderer = $renderer;
}

sub get-psgi-app() is export {
    return app.get-psgi-app();
}

sub baile($port = 3000) is export {
    my $psgi-app = app.get-psgi-app();
    given HTTP::Easy::PSGI.new(:host<0.0.0.0>, :$port) {
        .app($psgi-app);
        say "Entering the development dance floor: http://0.0.0.0:$port";
        .run;
    }
}
