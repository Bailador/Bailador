use Test;
use Bailador;
use Bailador::Test;

plan 3;

get '/die' => sub { die "oh no!" }
get '/fail' => sub { fail "oh no!" }
get '/exception' => sub { X::NYI.new(feature => 'NYI').throw }

is-deeply get-psgi-response('GET', '/die'),        [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles die';
is-deeply get-psgi-response('GET', '/fail'),       [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles fail';
is-deeply get-psgi-response('GET', '/exception'),  [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles thrown exception';
