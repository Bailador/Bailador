use Test;
use Bailador;
use Bailador::Test;

plan 10;

get '/foo' => sub { }
get '/echo' => sub { return 'Echo: ' ~ (request.params<text> // '')}
get '/echo2/:text' => sub ($text) { return 'Echo2: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}
post '/bar' => sub { }
post '/echo3/:text' => sub ($text) { return 'Echo3: ' ~ join('-', $text,  (request.params<text> // ''), (request.params('body')<text> // ''), (request.params('query')<text> // ''))}

route-exists('GET', '/foo');
route-doesnt-exist('POST', '/foo');

route-exists('POST', '/bar');
route-doesnt-exist('GET', '/bar');

route-exists('GET', '/foo?name=bar');

{
    my $resp = get-psgi-response('GET', 'http://127.0.0.1:1234/echo');
    is_deeply $resp, [200, ["Content-Type" => "text/html"], 'Echo: '], 'echo';
}

{
    my $resp = get-psgi-response('GET', 'http://127.0.0.1:1234/echo?text=bar');
    is_deeply $resp, [200, ["Content-Type" => "text/html"], 'Echo: bar'], 'echo with text';
}

{
    my $resp = get-psgi-response('GET', 'http://127.0.0.1:1234/echo2/foo');
    is_deeply $resp, [200, ["Content-Type" => "text/html"], 'Echo2: foo---'], 'echo with text';
}

{
    my $resp = get-psgi-response('GET', 'http://127.0.0.1:1234/echo2/foo?text=bar');
    is_deeply $resp, [200, ["Content-Type" => "text/html"], 'Echo2: foo-bar--bar'], 'echo with text';
}

{
    my $resp = get-psgi-response('POST', 'http://127.0.0.1:1234/echo3/foo?text=bar', 'text=zorg');
    is_deeply $resp, [200, ["Content-Type" => "text/html"], 'Echo3: foo-zorg-zorg-bar'], 'echo with text';
}

