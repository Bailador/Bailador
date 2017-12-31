use v6.c;

use Bailador::Configuration;
use Bailador::Hookable;

role Bailador::Plugin does Bailador::Hookable {
    has %.config;
}

class Bailador::Plugins {
    has %!plugins = {};

    method add(Str:D $name, Bailador::Plugin:D $plugin) {
        %!plugins.{$name} = $plugin;
    }

    method get(Str:D $name) {
        return %!plugins.{$name};
    }

    method getall() {
        return %!plugins.values;
    }

    method detect(Bailador::Configuration $config) {
        for $config.plugins.keys -> $name {
            my $plugin_conf= $config.plugins{$name};
            my $package = 'Bailador::Plugin::' ~ $name;
            try {
                require ::($package);
                 $.add($name, ::($package).new(config => $plugin_conf));
            }
        }
    }
}
