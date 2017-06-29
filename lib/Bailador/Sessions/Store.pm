use v6.c;

role Bailador::Sessions::Store {
    method store-session(Str $session-id, Hash $session) { ... }
    method fetch-session(Str $session-id) returns Hash { ... }
    method delete-session(Str $session-id) { ... }
}
