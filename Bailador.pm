module Bailador;

use HTTP::Easy::PSGI;

my %routes;
%routes<GET>  = [];
%routes<POST> = [];

my $current-request;

class Bailador::Request {
    has $.env;

    method params {
        my %ret;
        for $.env<psgi.input>.split('&') -> $p {
            my $pair = $p.split('=');
            %ret{$pair[0]} = $pair[1];
        }
        return %ret;
    }

    method port        { $.env<SERVER_PORT>      }
    method request_uri { $.env<REQUEST_URI>      }
    method uri         { self.request_uri        }
    method path        { $.env<PATH_INFO>        }

    method method      { $.env<REQUEST_METHOD>   }
    method is_get      { self.method eq 'GET'    }
    method is_post     { self.method eq 'POST'   }
    method is_put      { self.method eq 'PUT'    }
    method is_delete   { self.method eq 'DELETE' }
    method is_head     { self.method eq 'HEAD'   }
    method is_patch    { self.method eq 'PATCH' }

    method content_type   { $.env<CONTENT_TYPE>   }
    method content_length { $.env<CONTENT_LENGTH> }
    method body           { $.env<psgi.input>     }
}

multi get(Pair $x) is export {
    %routes<GET>.push: $x;
    return $x;
}

multi post(Pair $x) is export {
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

    given HTTP::Easy::PSGI.new(port => 3000) {
        .app($app);
        .run;
    }
}
