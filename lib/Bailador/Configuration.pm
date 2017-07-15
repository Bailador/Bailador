use v6.c;

use YAMLish;

my @config-file-extensions = 'yml', 'yaml';

class Bailador::Configuration {
    ## CONFIGURATION FILE
    has Str $.config-dir is rw = '.';
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

    ## Terminal output
    has Bool $.terminal-color is rw = False;

    ## SESSION RELATED STUFF
    has Str $.cookie-name is rw       = 'bailador';
    has Str $.cookie-path is rw       = '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw          = 'changeme';
    has Str $.backend is rw           = "Bailador::Sessions::Store::Memory";

    ## LOGGING
    has Str $.log-format is rw = '\d (\s) \m';
    has @.log-filter is rw     = ('severity' => '>=warning');

    method !variants($filename) {
        my @pieces = $filename.split('.');
        my $extend-me = @pieces[*-2];
        return gather {
            take $filename;

            @pieces[*-2] = $extend-me ~ '-local';
            take join '.', @pieces;

            @pieces[*-2] = $extend-me ~ '-' ~ $.mode;
            take join '.', @pieces;
        }
    }

    method load-from-dir($app-dir) {
        my $config-dir = $.config-dir.IO.is-absolute ?? $.config-dir.IO !! $app-dir.IO.child($.config-dir);
        for self!variants($.config-file) -> $f {
            my $config-file = $f.IO.is-absolute ?? $f.IO !! $config-dir.child($f);
            if $.check-config-file($config-file) {
                $.load-from-file($config-file);
            }
        }
    }

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

    method check-config-file(IO::Path $file) {
        if $file.IO ~~ :e && @config-file-extensions.contains($file.IO.extension) {
            return True;
        } elsif $file.IO !~~ :e {
            warn "The configuration file $file wasn't found." unless self.config-file ~ 'settings.yaml';
            return False;
        } elsif not @config-file-extensions.contains($file.IO.extension) {
            warn $file.IO.extension ~ ' format is not supported.';
            return False;
        }
    }

    method load-from-file(IO::Path $file) {
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
