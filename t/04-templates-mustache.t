use v6.c;

use Test;

use Bailador;
use Bailador::Template::Mustache;
use Bailador::Test;

plan 6;

get '/a' => sub { template 'simple.mustache', { 'foo' => 'bar' } }
get '/b' => sub { template 'simple.mustache', { 'foo' => 'bar' } }

renderer(Bailador::Template::Mustache.new);

my $p6w-app = baile('p6w');

my $resp1 = get-psgi-response($p6w-app, 'GET',  '/a');
is $resp1[0], 200;
is-deeply $resp1[1], ["Content-Type" => "text/html"];

if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    ok $resp1[2] ~~ /'a happy bar'\r?\n/;
}

my $resp2 = get-psgi-response($p6w-app, 'GET',  '/b');
is $resp2[0], 200;
is-deeply $resp2[1], ["Content-Type" => "text/html"];
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    ok $resp2[2] ~~ /'a happy bar'\r?\n/;
}
