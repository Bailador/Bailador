use Test;
use Bailador;
use Bailador::Test;

plan 5;

get '/foo' => sub { }
post '/bar' => sub { }

route-exists('GET', '/foo');
route-doesnt-exist('POST', '/foo');

route-exists('POST', '/bar');
route-doesnt-exist('GET', '/bar');

route-exists('GET', '/foo?name=bar');
