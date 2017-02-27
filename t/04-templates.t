use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 6;

get '/' => sub { template 'simple.tt', 'bar' }

my $resp1 = get-psgi-response('GET',  '/');
is $resp1[0], 200;
is-deeply $resp1[1], ["Content-Type" => "text/html"];
ok $resp1[2] ~~ /'a happy bar'\r?\n/;

Bailador::import(rootdir => $?FILE.IO.dirname);

get '/' => sub { template 'simple.tt', 'bar' }

my $resp2 = get-psgi-response('GET',  '/');
is $resp2[0], 200;
is-deeply $resp2[1], ["Content-Type" => "text/html"];
ok $resp2[2] ~~ /'a happy bar'\r?\n/;
