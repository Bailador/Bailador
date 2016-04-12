#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;

sessions-config.cookie-expiration = 60 * 5; # 5minutes
sessions-config.hmac-key = 'my-key';

get '/' => sub {
    my $session = session;

    if ($session<user>:exists) {
        # ...
        # hello user
        return "Hello {$session<user>}";
    } else {
        #...
        # ask for user
        $session<user> = "ufobat";
        return "Whats your name?";
    }
}


baile;
