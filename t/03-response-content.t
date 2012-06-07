use Test;
use Bailador;
use Bailador::Test;

plan 7;

get '/foo' => sub { "foo" }
post '/bar' => sub { "bar" }

get '/baz' => sub { { foo => "bar", baz => 5 } }

get '/params/:foo'    => sub ($foo) { "a happy $foo" }
get /'/regexes/'(.+)/ => sub ($foo) { "a happy $foo" }

response-content-is   'GET', '/foo', "foo";
response-content-isnt 'GET', '/bar', "bar";

response-content-is   'POST', '/bar', "bar";
response-content-isnt 'POST', '/foo', "foo";

response-content-is 'GET', '/params/bar',  'a happy bar';
response-content-is 'GET', '/regexes/bar', 'a happy bar';

todo 'returning complex structs NYI';
response-content-is-deeply 'GET', '/baz', { foo => "bar", baz => 5 };
