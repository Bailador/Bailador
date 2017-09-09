#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use JSON::Fast;
use Bailador;

app.config.mode = 'development';

get '/' => sub {
    content_type('application/json');
    my %person =
        name => 'Foo',
        id   => 42,
        courses => ['Perl', 'Web Development'],
    ;
    return to-json %person;
}

baile();

