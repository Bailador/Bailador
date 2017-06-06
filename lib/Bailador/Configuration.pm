use v6;

class Bailador::Configuration {
    ## USER DEFINED STUFF
    has %.user-defined-stuff;

    ## GENERAL STUFF
    has Str $.mode is rw where "production"|"development" = "production";
    has Str $.host is rw                                  = "127.0.0.1";
    has Int $.port is rw                                  = 3000;
    has Str $.layout is rw;

    ## Commands
    has Bool $.command-detection is rw = True;
    has Str  $.default-command is rw;

    ## SESSION RELATED STUFF
    has Str $.cookie-name is rw       = 'bailador';
    has Str $.cookie-path is rw       = '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw          = 'changeme';
    has Str $.backend is rw           = "Bailador::Sessions::Store::Memory";


    method load-from-array(@args) {
        for @*ARGS -> ($k, $v) { self.set($k, $v); }
    }
    method load-from-env() {
        if %*ENV<BAILADOR> {
            my @pairs = %*ENV<BAILADOR>.split(',');
            for @pairs -> $p {
                my ( $k, $v ) = $p . split(/<[:=]>/);
                say "key: $k value: $v";
                set($k, $v);
            }
        }
    }

    multi method set($key, $value) {
        if self.^can($key) {
            self."$key"() = $value;
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
            self."$key"(),
        } else {
            %.user-defined-stuff{$key};
        }
    }

    multi method FALLBACK(Str $name) {
        say "FALLBACK", $name;
        self.get($name);
    }
    multi method FALLBACK(Str $name, $value) {
        say "FALLBACK", $name, "value", $value;
        self.set($name, $value);
    }
}
