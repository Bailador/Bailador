use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 28;
config.log-filter = (severity => '>=error');

get '/foo' => sub { }
get '/x-y' => sub { }
get '/echo' => sub { return 'Echo: ' ~ (request.params<text> // '')}
get '/echo2/:text' => sub ($text) { return 'Echo2: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}
post '/bar' => sub { }
post '/echo3/:text' => sub ($text) { return 'Echo3: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}

# request methods when using GET requests
get '/a' => sub { 'port=' ~ request.port }
get '/b' => sub { 'request_uri=' ~ request.request_uri }
get '/c' => sub { 'uri=' ~ request.uri }
get '/d' => sub { 'path=' ~ request.path }
get '/e' => sub { 'method=' ~ request.method }
get '/f' => sub { join '-', request.is_get, request.is_post, request.is_put, request.is_delete, request.is_head, request.is_patch }
get '/g' => sub { request.content_type }
get '/h' => sub { request.content_length }
get '/i' => sub { request.body }

post '/a' => sub { 'port=' ~ request.port }
post '/b' => sub { 'request_uri=' ~ request.request_uri }
post '/c' => sub { 'uri=' ~ request.uri }
post '/d' => sub { 'path=' ~ request.path }
post '/e' => sub { 'method=' ~ request.method }
post '/f' => sub { join '-', request.is_get, request.is_post, request.is_put, request.is_delete, request.is_head, request.is_patch }
post '/g' => sub { request.content_type }
post '/h' => sub { request.content_length }
post '/i' => sub { request.body }


# call baile just once
my $p6w-app = baile('p6w');

is-deeply get-psgi-response($p6w-app, 'GET', '/foo'),  [200, ["Content-Type" => "text/html"], ''],              'route GET /foo exists';
is-deeply get-psgi-response($p6w-app, 'POST', '/foo'), [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route POST /foo does not exist';
is-deeply get-psgi-response($p6w-app, 'POST', '/bar'), [200, ["Content-Type" => "text/html"], ''],              'route POST /bar exists';
is-deeply get-psgi-response($p6w-app, 'GET', '/bar'),  [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /bar does not exist';

is-deeply get-psgi-response($p6w-app, 'GET', '/x-y'),  [200, ["Content-Type" => "text/html"], ''],              'route GET /foo exists';

is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/echo'),               [200, ["Content-Type" => "text/html"], 'Echo: '], 'echo';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/echo?text=bar'),      [200, ["Content-Type" => "text/html"], 'Echo: bar'], 'echo with text';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/echo2/foo'),          [200, ["Content-Type" => "text/html"], 'Echo2: foo---'], 'echo with text';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/echo2/foo?text=bar'), [200, ["Content-Type" => "text/html"], 'Echo2: foo-bar--bar'], 'echo with text';

is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:1234/echo3/foo?text=bar', 'text=zorg'), [200, ["Content-Type" => "text/html"], 'Echo3: foo-zorg-zorg-bar'], 'echo with text';

is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/a?text=bar'), [200, ["Content-Type" => "text/html"], 'port=1234'], 'port';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/b?text=bar'), [200, ["Content-Type" => "text/html"], 'request_uri=/b?text=bar'], 'request_uri';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/c?text=bar'), [200, ["Content-Type" => "text/html"], 'uri=/c?text=bar'], 'uri';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/d?text=bar'), [200, ["Content-Type" => "text/html"], 'path=/d'], 'path';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/e?text=bar'), [200, ["Content-Type" => "text/html"], 'method=GET'], 'method';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/f?text=bar'), [200, ["Content-Type" => "text/html"], 'True-False-False-False-False-False'], 'is';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/g?text=bar'), [200, ["Content-Type" => "text/html"], ''], 'content_type';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/h?text=bar'), [200, ["Content-Type" => "text/html"],''], 'content_length';
is-deeply get-psgi-response($p6w-app, 'GET', 'http://127.0.0.1:1234/i?text=bar'), [200, ["Content-Type" => "text/html"], ''], 'body';

is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/a?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'port=9876'], 'port';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/b?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'request_uri=/b?text=bar'], 'request_uri';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/c?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'uri=/c?text=bar'], 'uri';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/d?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'path=/d'], 'path';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/e?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'method=POST'], 'method';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/f?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'False-True-False-False-False-False'], 'is';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/g?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], ''], 'content_type';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/h?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], ''], 'content_length';
is-deeply get-psgi-response($p6w-app, 'POST', 'http://127.0.0.1:9876/i?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'text=foo'], 'body';
