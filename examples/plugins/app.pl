#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use Bailador;

app.config.plugins = {param => 1};

get '/' => sub {
    template 'index.tt', { version => $version };
}

baile();
