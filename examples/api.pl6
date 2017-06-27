#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;
use JSON::Fast;

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

