use Test;
use Bailador;
use Bailador::Test;

plan 6;

get '/die' => sub { die "oh no!" }
get '/fail' => sub { fail "oh no!" }
get '/exception' => sub { X::NYI.new(feature => 'NYI').throw }

my %data;

%data = run-psgi-request('GET', '/die');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles die';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request('GET', '/fail');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles fail';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request('GET', '/exception');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles thrown exception';
like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
