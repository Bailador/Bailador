use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 13;

# Note: On Windows the following tests fail: 2 3 5 6 8 9 11 12
# They are skipped for now.

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
# test 2:
if $*DISTRO.is-win {
    skip "Test 'discovered mime-type' fails on Windows", 1;
}
else {
    is $response[1], ["Content-Type" => "text/plain;charset=UTF-8" ], 'discovered mime-type';
}
# test 3:
if $*DISTRO.is-win {
    skip "Test 'same content' fails on Windows", 1;
}
else {
    is $response[2], "my content\n".encode, 'same content';
}

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, 'GET', '/foobar.bin');
# test 4:
is $response[0], 200, "Request GET /foobar.bin";
# test 5:
if $*DISTRO.is-win {
    skip "Test 'explicit mime-type $mime-type' fails on Windows", 1;
}
else {
    is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
}
# test 6:
if $*DISTRO.is-win {
    skip "Test 'same content' fails on Windows", 1;
}
else {
    is $response[2], "my content\n".encode, 'same content';
}

# Download file served with default mime-type
$response = get-psgi-response($p6w-app, 'GET', '/unknown');
# test 7:
is $response[0], 200, "Request GET /unknown";
# test 8:
if $*DISTRO.is-win {
    skip "Test 'unknown (default) mime-type $default-mime-type' fails on Windows", 1;
}
else {
    is $response[1], ["Content-Type" => $default-mime-type], 'unknown (default) mime-type ' ~ $default-mime-type;
}
# test 9:
if $*DISTRO.is-win {
    skip "Test 'same content' fails on Windows", 1;
}
else {
    is $response[2], "unknown\n".encode, 'same content';
}

# Download file served with explicit mime-type
$response = get-psgi-response($p6w-app, 'GET', '/unknown.ex');
# test 10:
is $response[0], 200, "Request GET /unknown.ex";
# test 11:
if $*DISTRO.is-win {
    skip "Test 'explicit mime-type $mime-type' fails on Windows", 1;
}
else {
    is $response[1], ["Content-Type" => $mime-type], 'explicit mime-type ' ~ $mime-type;
}
# test 12:
if $*DISTRO.is-win {
    skip "Test 'same content' fails on Windows", 1;
}
else {
    is $response[2], "unknown\n".encode, 'same content';
}

# Wrong URL -> 404
$response = get-psgi-response($p6w-app, 'GET', '/fail');
# test 13:
is $response[0], 404, "Request GET /fail";

# vim:syntax=perl6
