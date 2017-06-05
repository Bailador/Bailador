use v6;

use YAMLish;

class Bailador::Configuration {
    ## CONFIGURATION FILE
    has Str $.config_file = 'settings.yaml';

    ## GENERAL STUFF
    has Str $.mode is rw where "production"|"development" = "production";
    has Str $.host is rw                                  = "127.0.0.1";
    has Int $.port is rw                                  = 3000;
    has Str $.layout is rw;

    ## SESSION RELATED STUFF
    has Str $.cookie-name is rw       = 'bailador';
    has Str $.cookie-path is rw       = '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw          = 'changeme';
    has Str $.backend is rw           = "Bailador::Sessions::Store::Memory";

    method load-from-env() {
        if %*ENV<BAILADOR> {
            my @pairs = %*ENV<BAILADOR>.split(',');
            for @pairs -> $p {
                my ( $k, $v ) = $p . split(/<[:=]>/);
                if $k eq 'mode' {
                    $.mode = $v;
                }
                if $k eq 'port' {
                    $.port = $v.Int;
                }
                if $k eq 'host' {
                    $.host = $v;
                }
            }
        }
    }

    method load-from-file() {
        unless $.config_file.IO.e {
            warn "The configuration file wasn't found.";
            warn "Bailador will use his default configuration.";
        }

        if $.config_file.IO.extension ~~ 'yaml' | 'yml' {
            try {
                my $yaml = slurp $.config_file;
                my %config = load-yaml($yaml);
                for %config.kv -> $k, $v {
                    given $k {
                        when 'mode' {
                            $.mode = $v;
                        }
                        when 'port' {
                            $.port = $v;
                        }
                        when 'host' {
                            $.host = $v;
                        }
                    }
                }
                return;
            }
            warn 'Error while loading the YAML config file.';
            warn 'Bailador will use his default configuration.';
        }
    }
}
