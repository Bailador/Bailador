use v6;

use Test;

use Bailador;

Bailador::import;
use Bailador::Test;

plan 7;

get '/' => sub {
	template 'index.tt';
}


## Default configuration

my $resp1 = get-psgi-response('GET',  '/');
is $resp1[0], 200;
is-deeply $resp1[1], ["Content-Type" => "text/html"];
ok $resp1[2], '<h1>Hello World !</h1>';

## Customized configuration

my $app = Bailador::App.new;
isa-ok $app, Bailador::App;

my $config = $app.config;
isa-ok $config, Bailador::Configuration;

$config.views = 'templates';
my $resp2 = get-psgi-response('GET',  '/');
is $resp2[0], 200;
is-deeply $resp2[1], ["Content-Type" => "text/html"];
ok $resp2[2], '<h1>Hello World !</h1>';
