use Test;
use Bailador;
use Bailador::Test;

plan 7;

get '/foo' => sub { "foo text" }
post '/bar' => sub { "peti bar" }

get '/baz' => sub { { foo => "bar", baz => 5 } }

get '/params/:foo'    => sub ($foo) { "a happy $foo" }
get /'/regexes/'(.+)/ => sub ($foo) { "a happy $foo" }

is_deeply get-psgi-response('GET',  '/foo'),  [200, ["Content-Type" => "text/html"], 'foo text'],       'route GET /foo returns content';
is_deeply get-psgi-response('POST', '/bar'),  [200, ["Content-Type" => "text/html"], 'peti bar'],       'route POST /bar returns content';

is_deeply get-psgi-response('POST', '/foo'),  [404, ["Content-Type" => "text/html"], 'Not found'],      'route POST /foo not found';
is_deeply get-psgi-response('GET',  '/bar'),  [404, ["Content-Type" => "text/html"], 'Not found'],      'route GET /bar not found';

is_deeply get-psgi-response('GET',  '/params/bar'),   [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /params/bar returns content';
is_deeply get-psgi-response('GET',  '/regexes/bar'),  [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /regexes/bar returns content';

todo 'returning complex structs NYI';
response-content-is-deeply 'GET', '/baz', { foo => "bar", baz => 5 };
