use v6.c;
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

our sub import(Str :$rootdir) {
    app.location = $rootdir || callframe(1).file.IO.dirname;
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

sub patch(Pair $x) is export {
    app.add_route: 'PATCH', $x;
    return $x;
}

sub prefix(Pair $x) is export {
    app.prefix($x);
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

sub sessions-config is export {
    return app.sessions-config;
}

sub uri-for(Str $path) is export {
    return app.request.uri-for($path);
}

sub renderer(Bailador::Template $renderer) is export {
    app.renderer = $renderer;
}

sub get-psgi-app() is export {
    return app.get-psgi-app();
}

sub redirect(Str $location) is export {
    app.redirect($location);
}

sub baile($port is copy = 3000, $host is copy = '127.0.0.1', :$debug = False) is export {
    app.debug = $debug;

    if %*ENV<BAILADOR> {
        my @pairs = %*ENV<BAILADOR>.split(',');
        for @pairs -> $p {
            my ($k, $v) = $p.split(/<[:=]>/);
            if $k eq 'debug' {
                app.debug = True;
            }
            if $k eq 'port' {
                $port = $v.Int;
            }
            if $k eq 'host' {
                $host = $v;
            }
        }
    }
    my $psgi-app = app.get-psgi-app();
    given HTTP::Easy::PSGI.new(:host($host),:port($port)) {
        .app($psgi-app);
        say "Entering the development dance floor{app.debug ?? ' in debug mode' !! ''}: http://$host:$port";
        .run;
    }
}
