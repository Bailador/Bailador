#!/usr/bin/env perl6
use v6.c;
use lib 'lib';
use Bailador;

app.config.default-content-type = 'application/json';

get '/' => sub {
    my %person =
        name => 'Foo',
        id   => 42,
        courses => ['Perl', 'Web Development'],
    ;
    return to-json %person;
}

baile();
