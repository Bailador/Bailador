use v6;

use Digest;
use Digest::HMAC;

use Bailador::Configuration;
use Bailador::Sessions::Store;
use Bailador::Request;
use Bailador::Response;

class Bailador::Sessions {
    has Bailador::Configuration $!config;
    has Bailador::Sessions::Store $.sessions-store;

    has %!session-expiration;

    submethod BUILD(:$!config) {
        require ::($!config.backend);
        $!sessions-store := ::($!config.backend).new;
    }

    method !get-session-id(Bailador::Request $r) {
        my $cookies = $r.cookies();
        my Str $unchecked-session-id;
        if $cookies{ $!config.cookie-name }:exists {
            $unchecked-session-id = $cookies{$!config.cookie-name}[0];
        }
        return $unchecked-session-id;
    }

    method load(Bailador::Request $r) {
        my $cookies = $r.cookies();
        my $session-id;

        if my $unchecked-session-id = self!get-session-id($r) {

            # validate session
            my ($data, $hmac) = $unchecked-session-id.split(/\-\-/, 2);
            my $check-hmac = hmac-hex($!config.hmac-key, $data, &md5);
            if $hmac eq $check-hmac {
                if %!session-expiration{$unchecked-session-id}:exists and %!session-expiration{$unchecked-session-id} < DateTime.now {
                    # TODO after the timeout its better to delete them right now
                    self.delete-session($unchecked-session-id);
                }else{
                    $session-id = $unchecked-session-id;
                }
            }else{
                note "Session ID HMAC mismatch - someone trying to guess session IDs";
            }
        }

        unless $session-id {
            my $data = md5($*PID ~ now.Rat ~ rand).list.fmt('%02x', '');
            my $hmac = hmac-hex($!config.hmac-key, $data, &md5);
            $session-id = $data ~ '--' ~ $hmac;
        }
        my DateTime $expires = DateTime.now.later( second => $!config.cookie-expiration );
        %!session-expiration{$session-id} = $expires;
        my $session = $.sessions-store.fetch-session($session-id);
        $r.env<bailador.session-id> = $session-id;
        $r.env<bailador.session> = $session;
        return $session;
    }

    method store(Bailador::Response $r, Hash $env) {
        if $env<bailador.session-id>:exists and $env<bailador.session>:exists {
            my $session-id = $env<bailador.session-id>;
            my $session = $env<bailador.session>;
            $r.cookie($!config.cookie-name, $session-id, :path($!config.cookie-path));
            $.sessions-store.store-session($session-id, $session);
        }
    }

    multi method delete-session(Str:D $session-id) {
        $.sessions-store.delete-session($session-id);
        %!session-expiration{$session-id}:delete;
    }

    multi method delete-session(Bailador::Request $r) {
        my Str $session-id = self!get-session-id($r);
        $r.env<bailador.session-id>:delete;
        $r.env<bailador.session>:delete;
        self.delete-session($session-id) if $session-id;
    }
}
