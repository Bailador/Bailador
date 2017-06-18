#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;

get '/' => sub {
    'Hello, Bailador!';
}

get '/config' => sub {
    %*ENV<BAILADOR>;
}

baile();
