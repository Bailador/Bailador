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

    # https and tls stuff
    has Bool $.tls-mode is rw = False;
    has %.tls-config is rw = ();

    # has Str $.default-content-type is rw = 'text/html;charset=UTF-8';
    has Str $.default-content-type is rw = 'text/html';
    has Str $.file-discovery-content-type is rw = 'application/octet-stream';

    ## Commands
    has Bool $.command-detection is rw = True;
    has Str  $.default-command is rw;
    has Str  $.watch-command is rw = 'easy';
    has @.watch-list is rw;

    ## Terminal output
    has Bool $.terminal-color is rw = False;
    has Str  $.terminal-color-trace is rw;
    has Str  $.terminal-color-debug is rw;
    has Str  $.terminal-color-info is rw;
    has Str  $.terminal-color-notice is rw    = 'blue';
    has Str  $.terminal-color-warning is rw   = 'yellow';
    has Str  $.terminal-color-error is rw     = 'red';
    has Str  $.terminal-color-critical is rw  = 'red';
    has Str  $.terminal-color-alert is rw     = 'red';
    has Str  $.terminal-color-emergency is rw = 'red';

    ## SESSION RELATED STUFF
    has Str $.cookie-name is rw       = 'bailador';
    has Str $.cookie-path is rw       = '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw          = 'changeme';
    has Str $.backend is rw           = "Bailador::Sessions::Store::Memory";

    ## LOGGING
    # Available outputs : 'terminal:stdout', 'terminal:stderr', 'file:///path/to/log.log'
    # Available template-format: 'common', 'combined' and 'simple' wich are defaults in Apache ;
    #                     '' (empty, defaults to Bailador)
    # Available format place-handlers : \d, \c, \m, …
    has @.logs where * ~~ Pair = [
      # Accesses logs, in combined format
      # 'file:logs/access.log' => { 'template-match' => 'http-requests', 'template-format' => 'combined' },
      # Error logs, in 'simple' Apache format
      # 'file:logs/error.log'  => { 'category' => 'request-error', 'severity' => 'error', 'format' => 'simple' },
      # Everything, including accesses and error (in Bailador format)
      # 'terminal:stderr'      => { 'severity' => '>=warning', },
      'p6w:errors'           => { 'severity' => '>=warning'   },
    ];

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
