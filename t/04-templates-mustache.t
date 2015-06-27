use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

use Bailador::Template::Mustache;

plan 3;

get '/' => sub { template 'simple.mustache', { 'foo' => 'bar' } }

Bailador::App.current.renderer = Bailador::Template::Mustache.new;

my $resp = get-psgi-response('GET',  '/');
is $resp[0], 200;
is-deeply $resp[1], ["Content-Type" => "text/html"];
ok $resp[2] ~~ /'a happy bar'\r?\n/;
