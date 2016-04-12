#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;
Bailador::import; # for the template to work

# simple cases
get '/' => sub {
    "hello world"
}

get '/about' => sub {
    "about me"
}

get '/hello/:name' => sub ($name) {
    "Hello $name!"
};

# regexes, as usual
get /foo(.+)/ => sub ($x) {
    "regexes! I got $x"
}

get / '/' (.+) '-' (.+)/ => sub ($x, $y) {
    "$x and $y"
}

# junctions work too
get any('/h', '/help', '/halp') => sub {
    "junctions are cool"
}

# templates!
get / ^ '/template/' (.+) $ / => sub ($x) {
    template 'tmpl.tt', { name => $x }
}

baile;
