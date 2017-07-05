use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 3;

static-dir rx/ (.*) / =>  'data/';

my $response = get-psgi-response('GET', '/file.txt');
is $response[0], 200, 'status code';
is $response[1], ["Content-Type" => "text/plain;charset=UTF-8"], 'headers';
is $response[2], "my content\n".encode, 'same content';

done-testing;
