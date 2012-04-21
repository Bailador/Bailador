use Test;
use Bailador;
use Bailador::Test;

plan 4;

get '/foo' => sub { }
post '/bar' => sub { }

response-status-is   'GET', '/foo', 200;
response-status-isnt 'GET', '/bar', 200;

response-status-is   'POST', '/bar', 200;
response-status-isnt 'POST', '/foo', 200;
