use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 13;

my $mime-type          = "application/octet-stream";
my $default-mime-type  = "application/something-strange";
config.file-discovery-content-type = $default-mime-type;

# Setup routes
get '/foobar'     => sub { render-file("data/file.txt"); }
get '/foobar.bin' => sub { render-file("data/file.txt", :$mime-type); }
get '/unknown'    => sub { render-file("data/unknown.extention"); }
get '/unknown.ex' => sub { render-file("data/unknown.extention", :$mime-type); }

my $p6w-app = baile('p6w');

my $response = get-psgi-response($p6w-app, 'GET', '/foobar');
is $response[0], 200, "Request GET /foobar";
is $response[1], ["Content-Type" => "text/plain;charset=UTF-8" ], 'discovered mime-type';
is $response[2], "my content\n".encode, 'same content';

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, 'GET', '/foobar.bin');
is $response[0], 200, "Request GET /foobar.bin";
is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
is $response[2], "my content\n".encode, 'same content';

# Download file served with default mime-type
$response = get-psgi-response($p6w-app, 'GET', '/unknown');
is $response[0], 200, "Request GET /unknown";
is $response[1], ["Content-Type" => $default-mime-type], 'unknown (default) mime-type ' ~ $default-mime-type;
is $response[2], "unknown\n".encode, 'same content';

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, 'GET', '/unknown.ex');
is $response[0], 200, "Request GET /unknown.ex";
is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
is $response[2], "unknown\n".encode, 'same content';

# Wrong URL -> 404
$response = get-psgi-response($p6w-app, 'GET', '/fail');
is $response[0], 404, "Request GET /fail";

done-testing;

# vim:syntax=perl6
