use v6;

class Bailador::Configuration {
    ## GENERAL STUFF
    has Str $.mode is rw where "production"|"development" = "production";
    has Str $.host is rw                                  = "127.0.0.1";
    has Int $.port is rw                                  = 3000;

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
}
