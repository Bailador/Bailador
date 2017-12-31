#!/usr/bin/env perl6

use v6.c;
use lib 'examples/plugins/lib';
use lib 'lib';
use Data::Dump;
use Bailador;
use Bailador::Plugin::Example;

get '/' => sub {
    template 'index.tt', {
        title => 'Plugin Example',
        plugin_text => app.plugins.get('Example').sample
    };
}

baile();
