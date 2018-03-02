use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 3;

static-dir rx/ (.*) / =>  'data/';

# Call baile just once
my $p6w-app = baile('p6w');

my $response = get-psgi-response($p6w-app, 'GET', '/file.txt');
# test 1
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    is $response[0], 200, 'status code';
}

is $response[1], ["Content-Type" => "text/plain;charset=UTF-8"], 'headers';

# test 3
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    is $response[2], "my content\n".encode, 'same content';
}
