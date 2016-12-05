use v6;
use Test;
use Bailador::Test;
use Bailador;

plan 22;

my $prefixone-execution = 0;
my $prefixtwo-execution = 0;

get '/x' => { '/x' };

prefix '' => sub {
    prefix-enter sub {
        say "# prefix-enter for \"\"";
    };
    get '/inempty' => sub { '/inempty' };
};

prefix '/abc' => sub {
    get '/x' => sub { '/abc/x' };
    get '/y' => sub { '/abc/y' };
};

prefix '/xyz/:foo' => sub {
    prefix-enter sub ($number) {
        say "# prefix enter for /xyz/:foo  -URL: " ~  request.uri;
        $prefixone-execution++;
        return ($number %% 2);
    };
    get '/x' => sub { '/xyz/:foo/x' };
    get '/y' => sub { '/xyz/:foo/y' };

    prefix '/next' => sub {
        prefix-enter sub {
            say "# prefix enter for /match  -URL: " ~ request.uri;
            $prefixtwo-execution++;
            return True;
        };
        get '/x' => sub { '/xyz/:foo/next/x' };
        get '/y' => sub { '/xyz/:foo/next/y' };
    };

    get '/again' => sub { '/xyz/:foo/again' };
    # be careful! if you specify something for '' it matched everything,
    # so put this in the end of the route definition
    get ''       => sub { '/xyz/:foo' };
}

get '/y' => sub { '/y' };

is-deeply get-psgi-response('GET', '/x'),   [200, ["Content-Type" => "text/html"], '/x'], 'route GET /x';
is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

is-deeply get-psgi-response('GET', '/inempty'),   [200, ["Content-Type" => "text/html"], '/inempty'], 'route GET /inempty';
is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

is-deeply get-psgi-response('GET', '/abc/x'),   [200, ["Content-Type" => "text/html"], '/abc/x'], 'route GET /abc/x';
is-deeply get-psgi-response('GET', '/abc/y'),   [200, ["Content-Type" => "text/html"], '/abc/y'], 'route GET /abc/y';
is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

is-deeply get-psgi-response('GET', '/xyz/2/x'), [200, ["Content-Type" => "text/html"], '/xyz/:foo/x'], 'route GET /xyz/2/x';
is-deeply get-psgi-response('GET', '/xyz/3/y'), [404, ["Content-Type" => "text/html, charset=utf-8"], 'Not found'], 'route GET /xyz/3/y';
is-deeply get-psgi-response('GET', '/xyz/2'),   [200, ["Content-Type" => "text/html"], '/xyz/:foo'], 'route GET /xyz/2';
is($prefixone-execution , 3 , 'prefix /xyz/:foo executed 2 times');
is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

$prefixone-execution = 0;
$prefixtwo-execution = 0;
is-deeply get-psgi-response('GET', '/xyz/2/next/x'), [200, ["Content-Type" => "text/html"], '/xyz/:foo/next/x'], 'route GET /xyz/2/next/x';
is-deeply get-psgi-response('GET', '/xyz/2/next/y'), [200, ["Content-Type" => "text/html"], '/xyz/:foo/next/y'], 'route GET /xyz/2/next/y';
is($prefixone-execution , 2 , 'prefix /xyz/:foo executed 2 times');
is($prefixtwo-execution , 2 , 'prefix /xyz/:foo/next executed 4 times');

$prefixone-execution = 0;
$prefixtwo-execution = 0;
is-deeply get-psgi-response('GET', '/y'),   [200, ["Content-Type" => "text/html"], '/y'], 'route GET /y';
is($prefixone-execution , 0 , 'prefix /xyz/:foo executed 2 times');
is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next executed 4 times');
