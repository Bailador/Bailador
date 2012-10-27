use Test;
use Bailador;
use Bailador::Test;

plan 3;

post '/foo' => sub { request.env<psgi.input>.decode };

my $data = 'hello=world&a=1;b=2';
my $req  = Bailador::Request.new_for_request('POST', '/foo');
   $req.env<psgi.input> = $postdata.encode('utf-8');
my $resp = Bailador::dispatch_request($req);

lives_ok { eager $req.params<hello> }, 'Request data parses without dying';
is ~$resp.content, $data,   'POST data string roundtrips correctly';
is $req.params<a>, '1;b=2', 'application/x-www-form-urlencoded POST data should only split on &';
