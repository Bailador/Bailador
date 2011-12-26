module Bailador;

use HTTP::Easy::PSGI;

my %routes;
%routes<GET> = [];

multi get(Pair $x) is export {
    %routes<GET>.push: $x;
}

sub dispatch($env) {
    my $res = '';
    for %routes{$env<REQUEST_METHOD>}.list -> $r {
        if $env<REQUEST_URI> ~~ $r.key {
            if $/ {
                $res = $r.value.(|$/.list);
            } else {
                $res = $r.value.();
            }
        }
    }
    if $res {
        return [200, [ 'Content-Type' => 'text/plain' ], [$res]];
    } else {
        return [404, [ 'Content-Type' => 'text/plain' ], ['Not found']];
    }
}

sub baile is export {
    my $app = sub ($env) {
        return dispatch($env);
        my $res = dispatch($env);
    }

    given HTTP::Easy::PSGI.new {
        .app($app);
        .run;
    }
}
