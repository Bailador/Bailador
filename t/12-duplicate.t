use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 3;

get '/foo' => sub { "hello" }
is-deeply get-psgi-response('GET', '/foo'),  [200, ["Content-Type" => "text/html"], "hello"],              'route GET /foo exists';

get '/bar' => sub { "world" }

is-deeply get-psgi-response('GET', '/bar'),  [200, ["Content-Type" => "text/html"], "world"],              'route GET /bar exists';

try {
    get '/foo' => sub { "other" };
    CATCH {
        default {
            is $_.payload, "duplicate route: GET / ^ '/'foo [ \$ || <?before '/' > ] /";
        }
    }

}
