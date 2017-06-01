use v6;
use Test;
use Bailador;
use Bailador::Test;

plan 3;

post '/foo' => sub { request.env<p6w.input>.decode };

my $data = 'hello=world&a=1;b=2';
my $req  = Bailador::Request.new_for_request('POST', '/foo');
   $req.env<p6w.input> = $data.encode('utf-8');
skip 'fails with precompilation', 3;
#my $resp = Bailador::dispatch_request($req);
#
#lives_ok { eager $req.params<hello> }, 'Request data parses without dying';
#is ~$resp.content, $data,   'POST data string roundtrips correctly';
#is $req.params<a>, '1;b=2', 'application/x-www-form-urlencoded POST data should only split on &';
