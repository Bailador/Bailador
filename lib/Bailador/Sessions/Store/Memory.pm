use v6.c;

use Bailador::Sessions::Store;

class Bailador::Sessions::Store::Memory does Bailador::Sessions::Store {
    has %!memory;

    method store-session(Str $session-id, Hash $session) {
        %!memory{$session-id} = $session;
    }

    method fetch-session(Str $session-id) returns Hash {
        %!memory{$session-id} || Hash.new;
    }

    method delete-session(Str $session-id) {
        %!memory{$session-id}:delete;
    }
}
