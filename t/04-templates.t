use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 3;

get '/' => sub { template 'simple.tt', 'bar' }

my $resp = get-psgi-response('GET',  '/');
is $resp[0], 200;
is_deeply $resp[1], ["Content-Type" => "text/html"];
ok $resp[2] ~~ /'a happy bar'\r?\n/;
