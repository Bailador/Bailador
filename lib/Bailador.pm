module Bailador;
use Bailador::Request;
use HTTP::Easy::PSGI;

my %routes;
%routes<GET>  = [];
%routes<POST> = [];

my $current-request;

sub get(Pair $x) is export {
    %routes<GET>.push: $x;
    return $x;
}

sub post(Pair $x) is export {
    %routes<POST>.push: $x;
    return $x;
}

sub request is export { $current-request }

sub dispatch($env) {
    my $res = '';
    $current-request = Bailador::Request.new(:$env);
    for %routes{$env<REQUEST_METHOD>}.list -> $r {
        next unless $r;
        if $env<REQUEST_URI> ~~ $r.key {
            if $/ {
                $res = $r.value.(|$/.list);
            } else {
                $res = $r.value.();
            }
        }
    }
    if $res {
        return [200, [ 'Content-Type' => 'text/html' ], [$res]];
    } else {
        return [404, [ 'Content-Type' => 'text/plain' ], ['Not found']];
    }
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
