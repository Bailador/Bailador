use Test;
use Bailador;
use Bailador::Test;

plan 4;

get '/foo' => sub { }
post '/bar' => sub { }

route-exists('GET', '/foo');
route-doesnt-exist('POST', '/foo');

route-exists('POST', '/bar');
route-doesnt-exist('GET', '/bar');
