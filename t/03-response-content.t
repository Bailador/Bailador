use Test;
use Bailador;
use Bailador::Test;

plan 4;

get '/foo' => sub { "foo" }
post '/bar' => sub { "bar" }

response-content-is   'GET', '/foo', "foo";
response-content-isnt 'GET', '/bar', "bar";

response-content-is   'POST', '/bar', "bar";
response-content-isnt 'POST', '/foo', "foo";
