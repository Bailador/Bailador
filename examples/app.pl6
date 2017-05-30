#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;
Bailador::import; # for the template to work

# simple cases
get '/' => sub {
    "hello world"
}

get '/die' => sub {
    die 'This is an exception so you can see how it is handled';
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

get rx{ '/' (.+) '-' (.+) } => sub ($x, $y) {
    "$x and $y"
}

# templates!
get / ^ '/template/' (.+) $ / => sub ($x) {
    template 'tmpl.tt', { name => $x }
}

get '/env' => sub {
    my Str $result;
    for request.env.sort(*.key)>>.kv -> ($k, $v) {
        $result ~= "$k\t" ~ $v.perl ~ "\n";
    }
    app.render: content => $result, type => 'text/plain';
    $result;
}

baile();
