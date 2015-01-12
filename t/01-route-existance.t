use Test;
use Bailador;
use Bailador::Test;

plan 7;

get '/foo' => sub { }
get '/echo' => sub { return 'Echo: ' ~ (request.params<text> // '')}
post '/bar' => sub { }

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

