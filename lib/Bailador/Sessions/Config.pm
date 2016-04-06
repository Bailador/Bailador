use v6;

class Bailador::Sessions::Config {
    has Str $.cookie-name is rw = 'bailador';
    has Str $.cookie-path is rw= '/';
    has Int $.cookie-expiration is rw = 3600;
    has Str $.hmac-key is rw = 'changeme';
    has Str $.backend is rw = "Bailador::Sessions::Store::Memory";
}
