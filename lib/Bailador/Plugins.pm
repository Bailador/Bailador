use v6.c;

use Bailador::Configuration;

class Bailador::Plugins {
    has %.plugins = {};

    method add-namespace(Str:D $namespace) {
        @.namespaces.push: $namespace;
    }

    method get(Str:D $plugin) {
        return %.plugins.{$plugin};
    }

    method detect(Bailador::Configuration $config) {
        for $config.plugins.keys -> $plugin {
            my $plugin_conf= $config.plugins{$plugin};
            my $module = 'Bailador::Plugin::' ~ $plugin;
            try {
                require ::($module);
                 %.plugins.{$plugin} = ::($module).new(config => $plugin_conf);
            }
        }
    }
}

role Bailador::Plugin {
    has %.config;
}