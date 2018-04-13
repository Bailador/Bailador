use v6.c;

use Test;
use Bailador;
use Bailador::Test;

plan 9;

get '/' => sub { template 'index.tt'; }
get '/a' => sub { template 'simple.tt', 'bar' }
get '/c' => sub { template 'with-include.tt', 'bar' }

# Call baile just once
my $p6w-app = baile('p6w');

my $resp1 = get-psgi-response($p6w-app, 'GET',  '/a');
is $resp1[0], 200;
is-deeply $resp1[1], ["Content-Type" => "text/html"];
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    ok $resp1[2] ~~ /^ 'a happy bar' \r?\n$/;
}

my $resp2 = get-psgi-response($p6w-app, 'GET',  '/');
is $resp2[0], 200;
is-deeply $resp1[1], ["Content-Type" => "text/html"];
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    ok $resp2[2], '<h1>Hello World !</h1>';
}

my $resp3 = get-psgi-response($p6w-app, 'GET',  '/c');
is $resp3[0], 200;
is-deeply $resp3[1], ["Content-Type" => "text/html"];
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    ok $resp3[2] ~~ / '<pre>' \r? \n 'a happy bar' \r? \n /;
}
