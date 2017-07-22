use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 6;

config.default-content-type = 'config/default';

get '/default_autorender' => sub {
    "Hi";
}

get '/defined_autorender' => sub {
    content_type('application/json');
    '{}';
}

get '/defined_render' => sub {
    render(content => '{}', type => 'application/json');
}

get '/default_render' => sub {
    render(content => "Hi");
}

static-dir rx/ (.*) / =>  'data/';

# Call baile just once
my $p6w-app = baile('p6w');

my $response = get-psgi-response($p6w-app, 'GET', '/file.txt');
is $response[1], ["Content-Type" => "text/plain;charset=UTF-8"], 'content type discovery';

$response = get-psgi-response($p6w-app, 'GET', '/unknown.extention');
is $response[1], ["Content-Type" => "config/default"], 'content type discovery fallback';

$response = get-psgi-response($p6w-app, 'GET', '/default_autorender');
is $response[1], [Content-Type => 'config/default'], 'content type autorender default';

$response = get-psgi-response($p6w-app, 'GET', '/defined_autorender');
is $response[1], [Content-Type => 'application/json'], 'content type autorender defined';

$response = get-psgi-response($p6w-app, 'GET', '/default_render');
is $response[1], [Content-Type => 'config/default'], 'content type default';

$response = get-psgi-response($p6w-app, 'GET', '/defined_render');
is $response[1], [Content-Type => 'application/json'], 'content type defined';
