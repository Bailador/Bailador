#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use Bailador;

app.config.mode = 'development';

# simple cases
get '/' => sub {
    template 'index.html';
}

get '/page' => sub {
    template 'page.html';
}

get '/sub/page' => sub {
    template 'sub/page.html';
}

get '/sub/' => sub {
    template 'sub/index.html';
}


baile();

