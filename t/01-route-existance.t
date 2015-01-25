use Test;
use Bailador;
use Bailador::Test;

plan 9;

get '/foo' => sub { }
get '/echo' => sub { return 'Echo: ' ~ (request.params<text> // '')}
get '/echo2/:text' => sub ($text) { return 'Echo2: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}
post '/bar' => sub { }
post '/echo3/:text' => sub ($text) { return 'Echo3: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}

is_deeply get-psgi-response('GET', '/foo'),  [200, ["Content-Type" => "text/html"]],              'route GET /foo exists';
is_deeply get-psgi-response('POST', '/foo'), [404, ["Content-Type" => "text/html"], 'Not found'], 'route POST /foo does not exist';
is_deeply get-psgi-response('POST', '/bar'), [200, ["Content-Type" => "text/html"]],              'route POST /bar exists';
is_deeply get-psgi-response('GET', '/bar'),  [404, ["Content-Type" => "text/html"], 'Not found'], 'route GET /bar does not exist';

is_deeply get-psgi-response('GET', 'http://127.0.0.1:1234/echo'),               [200, ["Content-Type" => "text/html"], 'Echo: '], 'echo';
is_deeply get-psgi-response('GET', 'http://127.0.0.1:1234/echo?text=bar'),      [200, ["Content-Type" => "text/html"], 'Echo: bar'], 'echo with text';
is_deeply get-psgi-response('GET', 'http://127.0.0.1:1234/echo2/foo'),          [200, ["Content-Type" => "text/html"], 'Echo2: foo---'], 'echo with text';
is_deeply get-psgi-response('GET', 'http://127.0.0.1:1234/echo2/foo?text=bar'), [200, ["Content-Type" => "text/html"], 'Echo2: foo-bar--bar'], 'echo with text';

is_deeply get-psgi-response('POST', 'http://127.0.0.1:1234/echo3/foo?text=bar', 'text=zorg'), [200, ["Content-Type" => "text/html"], 'Echo3: foo-zorg-zorg-bar'], 'echo with text';

