module Bailador;

use HTTP::Server::Simple::PSGI;

my @routes;

multi get(Pair $x) is export {
    @routes.push: $x;
}

sub dispatch($env) {
    for @routes -> $r {
        if $env<REQUEST_URI> ~~ $r.key {
            if $/ {
                return $r.value.(|$/.list);
            } else {
                return $r.value.();
            }
        }
    }
    return "404";
}

sub bailar is export {
    my $app = sub ($env) {
        my $res = dispatch($env);
        return ['200', [ 'Content-Type' => 'text/plain' ], $res];
    }

    given HTTP::Server::Simple::PSGI.new {
        .host = 'localhost';
        .app($app);
        .run;
    }
}
