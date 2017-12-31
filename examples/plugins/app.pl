#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use lib 'examples/plugins/lib';
use Bailador;
use Bailador::Plugin::Example;
use Data::Dump;

get '/' => sub {
    template 'index.tt', {
        title => 'Plugin Example',
        plugin_text => app.plugins.get('Example').sample
    };
}

baile();
