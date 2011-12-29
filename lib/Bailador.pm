module Bailador;
use Bailador::Request;
use Bailador::Response;
use Ratel;
use HTTP::Easy::PSGI;

my %routes;
%routes<GET>  = [];
%routes<POST> = [];

my $current-request  = Bailador::Request.new;
my $current-response = Bailador::Response.new;
my $template-engine  = Ratel.new;

sub get(Pair $x) is export {
    %routes<GET>.push: $x;
    return $x;
}

sub post(Pair $x) is export {
    %routes<POST>.push: $x;
    return $x;
}

sub request is export { $current-request }

sub content_type(Str $type) is export {
    $current-response.headers<Content-Type> = $type;
}

sub status(Int $code) is export {
    $current-response.code = $code;
}

sub template(Str $tmpl, %params) is export {
    $template-engine.load("views/$tmpl");
    return $template-engine.render(|%params);
}

sub dispatch($env) {
    my $res = '';

    $current-request.env      = $env;
    $current-response.code    = 404;
    $current-response.content = 'Not found';
    $current-response.headers<Content-Type> = 'text/html';

    for %routes{$env<REQUEST_METHOD>}.list -> $r {
        next unless $r;
        if $env<REQUEST_URI> ~~ $r.key {
            $current-response.code = 200;
            if $/ {
                $current-response.content = $r.value.(|$/.list);
            } else {
                $current-response.content = $r.value.();
            }
        }
    }
    return $current-response.psgi;
}

sub baile is export {
    my $app = sub ($env) {
        return dispatch($env);
        my $res = dispatch($env);
    }

    given HTTP::Easy::PSGI.new(port => 3000) {
        .app($app);
        .run;
    }
}
