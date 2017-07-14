use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 3;

get '/foo' => sub { "hello" }
get '/bar' => sub { "world" }

try {
    get '/foo' => sub { "other" };
    CATCH {
        default {
            is $_.payload, "duplicate route: GET /foo (Bailador::Route::Simple)";
        }
    }

}

# Call baile just once
my $p6w-app = baile('p6w');

is-deeply get-psgi-response($p6w-app, 'GET', '/foo'),  [200, ["Content-Type" => "text/html"], "hello"],              'route GET /foo exists';
is-deeply get-psgi-response($p6w-app, 'GET', '/bar'),  [200, ["Content-Type" => "text/html"], "world"],              'route GET /bar exists';

