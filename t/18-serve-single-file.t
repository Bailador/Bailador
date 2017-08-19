use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 10;

my $mime-type = "application/octet-stream";
my $route-default = "/foobar";
my $route-explicit = "/foobar.bin";
my $route-unknown = "/unknown";
my $route-fail = "/fail";
my $method = "GET";

config.file-discovery-content-type = $mime-type;

# Setup routes
get $route-default      => sub { render-file("data/file.txt"); }
get $route-explicit     => sub { render-file("data/file.txt", :$mime-type); }
get $route-unknown      => sub { render-file("data/unknown.extention"); } # should be extention :(
#get $route-    => sub { render-file("data/unknown.extension", :$mime-type); }
# get file with unknown mimetype without explicit mime type -> check for default
# get file with unknown mimetype with explicit mime type -> check type

my $p6w-app = baile('p6w');

# Download file served with default mime-type
my $response = get-psgi-response($p6w-app, $method, $route-default);
is $response[0], 200, "Request " ~ $method ~ " " ~ $route-default;
is $response[1], ["Content-Type" => "text/plain;charset=UTF-8" ], 'discovered mime-type';
is $response[2], "my content\n".encode, 'same content';
#say $response.perl;

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, $method, $route-explicit);
is $response[0], 200, "Request " ~ $method ~ " " ~ $route-explicit;
is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
is $response[2], "my content\n".encode, 'same content';

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, $method, $route-unknown);
is $response[0], 200, "Request " ~ $method ~ " " ~ $route-unknown;
is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
#say $response.perl;
is $response[2], "unknown\n".encode, 'same content';

# Download file served with explicit mime-type
#$response = get-psgi-response($p6w-app, $method, $route-unknown);
#is $response[0], 200, "Request " ~ $method ~ " " ~ $route-unknown;
#is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
#is $response[2], "my content\n", 'same content';

# Wrong URL -> 404
$response = get-psgi-response($p6w-app, $method, $route-fail);
is $response[0], 404, "Request " ~ $method ~ " " ~ $route-fail;

done-testing;

# vim:syntax=perl6
