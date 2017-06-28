use v6;

use YAMLish;

class Bailador::Configuration {
    ## CONFIGURATION FILE
    has Str $.config-file is rw = 'settings.yaml';

    ## USER DEFINED STUFF
    has %.user-defined-stuff;

    ## GENERAL STUFF
    has Str $.mode is rw where "production"|"development" = "production";
    has Str $.host is rw                                  = "127.0.0.1";
    has Int $.port is rw                                  = 3000;
    has Str $.views is rw                                 = 'views';
    has Str $.layout is rw;

    ## Commands
    has Bool $.command-detection is rw = True;
    has Str  $.default-command is rw;
    has Str  $.watch-command is rw = 'easy';
    has @.watch-list is rw;

    ## SESSION RELATED STUFF
    has Str $.cookie-name is rw       = 'bailador';
    has Str $.cookie-path is rw       = '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw          = 'changeme';
    has Str $.backend is rw           = "Bailador::Sessions::Store::Memory";

    ## LOGGING
    has Str $.log-format is rw = '\d (\s) \m';
    has @.log-filter is rw     = ('severity' => '>=warning');

    method load-from-array(@args) {
        for @args -> ($k, $v) {
            self.set($k, $v);
        }
    }

    method load-from-hash(%config) {
        for %config.kv -> $k, $v {
            self.set($k, $v);
        }
    }

    method load-from-env() {
        if %*ENV<BAILADOR> {
            my @pairs = %*ENV<BAILADOR>.split(',');
            for @pairs -> $p {
                my ( $k, $v ) = $p . split(/<[:=]>/);
                self.set($k, $v);
            }
        }
    }

    method load-from-file(IO::Path $path) {
        my $file = $path.child($.config-file);
        unless $file.IO.e {
            # warn "The configuration file wasn't found.";
            # warn "Bailador will use his default configuration.";
            return
        }

        if $file.IO.extension ~~ 'yaml' | 'yml' {
            try {
                my $yaml = slurp $file;
                my %config = load-yaml($yaml);
                self.load-from-hash(%config);
                return;
            }
            warn 'Error while loading the YAML config file.';
            warn 'Bailador will use his default configuration.';
        }
    }

    multi method set($key, $value) {
        if self.^can($key) {
            my $type = self."$key"().^name;
            if $type eq 'Array' {
                self."$key"().push($value);
            } else {
                self."$key"() = $value."$type"();
            }
        } else {
            %.user-defined-stuff{$key} = $value;
        }
    }
    multi method set(Pair $x) {
        my $key = $x.key;
        self.set($x.key, $x.value);
    }

    method get(Str $key) {
        if self.^can($key) {
            self."$key"();
        } else {
            %.user-defined-stuff{$key};
        }
    }

    multi method FALLBACK(Str $name) {
        self.get($name);
    }

    multi method FALLBACK(Str $name, $value) {
        self.set($name, $value);
    }
}
