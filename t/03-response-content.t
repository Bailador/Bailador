use Test;
use Bailador;
use Bailador::Test;

plan 5;

get '/foo' => sub { "foo" }
post '/bar' => sub { "bar" }

get '/baz' => sub { { foo => "bar", baz => 5 } }

response-content-is   'GET', '/foo', "foo";
response-content-isnt 'GET', '/bar', "bar";

response-content-is   'POST', '/bar', "bar";
response-content-isnt 'POST', '/foo', "foo";

todo 'returning complex structs NYI';
response-content-is-deeply 'GET', '/baz', { foo => "bar", baz => 5 };
