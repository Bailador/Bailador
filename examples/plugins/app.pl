#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use lib 'examples/plugins/lib';
use Bailador;
use Bailador::Plugin::Example;
use Data::Dump;

get '/' => sub {
    app.plugins.add('Example', Bailador::Plugin::Example.new(config => {param => 'Test'}) );
    say Dump app.plugins;
    template 'index.tt', { title => 'Plugin Example' };
}

baile();
