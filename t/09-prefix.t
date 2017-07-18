use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 3;

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

# Call baile just once
my $p6w-app = baile('p6w');

subtest {
    plan 15;

    is-deeply get-psgi-response($p6w-app, 'GET', '/x'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/x'], 'route GET /x';
    is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
    is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

    is-deeply get-psgi-response($p6w-app, 'GET', '/inempty'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/inempty'], 'route GET /inempty';
    is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
    is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

    is-deeply get-psgi-response($p6w-app, 'GET', '/abc/x'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/abc/x'], 'route GET /abc/x';
    is-deeply get-psgi-response($p6w-app, 'GET', '/abc/y'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/abc/y'], 'route GET /abc/y';
    is($prefixone-execution , 0 , 'prefix /xyz/:foo not executed');
    is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');

    is-deeply get-psgi-response($p6w-app, 'GET', '/xyz/2/x'), [200, ["Content-Type" => "text/html;charset=UTF-8"], '/xyz/:foo/x'], 'route GET /xyz/2/x';
    is-deeply get-psgi-response($p6w-app, 'GET', '/xyz/3/y'), [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /xyz/3/y';
    is-deeply get-psgi-response($p6w-app, 'GET', '/xyz/2'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/xyz/:foo'], 'route GET /xyz/2';
    is($prefixone-execution , 3 , 'prefix /xyz/:foo executed 2 times');
    is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next not executed');
}


subtest {
    plan 4;

    $prefixone-execution = 0;
    $prefixtwo-execution = 0;

    is-deeply get-psgi-response($p6w-app, 'GET', '/xyz/2/next/x'), [200, ["Content-Type" => "text/html;charset=UTF-8"], '/xyz/:foo/next/x'], 'route GET /xyz/2/next/x';
    is-deeply get-psgi-response($p6w-app, 'GET', '/xyz/2/next/y'), [200, ["Content-Type" => "text/html;charset=UTF-8"], '/xyz/:foo/next/y'], 'route GET /xyz/2/next/y';
    is($prefixone-execution , 2 , 'prefix /xyz/:foo executed 2 times');
    is($prefixtwo-execution , 2 , 'prefix /xyz/:foo/next executed 4 times');
};

subtest {
    plan 3;

    $prefixone-execution = 0;
    $prefixtwo-execution = 0;

    is-deeply get-psgi-response($p6w-app, 'GET', '/y'),   [200, ["Content-Type" => "text/html;charset=UTF-8"], '/y'], 'route GET /y';
    is($prefixone-execution , 0 , 'prefix /xyz/:foo executed 2 times');
    is($prefixtwo-execution , 0 , 'prefix /xyz/:foo/next executed 4 times');
};
