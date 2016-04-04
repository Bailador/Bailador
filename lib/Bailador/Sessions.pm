use v6;

use Digest;
use Digest::HMAC;

use Bailador::Sessions::Config;
use Bailador::Sessions::Store;
use Bailador::Request;
use Bailador::Response;

class Bailador::Sessions {
    has Bailador::Sessions::Config $.sessions-config;
    has Bailador::Sessions::Store $.sessions-store;

    has %!session-expiration;
    
    submethod BUILD(:$!sessions-config) {
        require ::($!sessions-config.backend);
        $!sessions-store := ::($!sessions-config.backend).new;
    }
    
    method load(Bailador::Request $r) {
        my $cookies = $r.cookies();
        my $session-id;
        if $cookies{ $.sessions-config.cookie-name }:exists {
            my $unchecked-session-id = $cookies{$.sessions-config.cookie-name}[0];

            # validate session
            my ($data, $hmac) = $unchecked-session-id.split(/\-\-/, 2);
            my $check-hmac = hmac-hex($.sessions-config.hmac-key, $data, &md5);
            if $hmac eq $check-hmac {
                if %!session-expiration{$unchecked-session-id}:exists and %!session-expiration{$unchecked-session-id} < DateTime.now {
                    # TODO after the timeout its better to delete them right now
                    $.sessions-store.delete-session($unchecked-session-id);
                }else{
                    $session-id = $unchecked-session-id;
                }
            }else{
                note "Session ID HMAC mismatch - someone trying to guess session IDs";
            }
        }

        unless $session-id {
            my $data = md5($*PID ~ now.Rat ~ rand).list.fmt('%02x', '');
            my $hmac = hmac-hex($.sessions-config.hmac-key, $data, &md5);
            $session-id = $data ~ '--' ~ $hmac;
            my DateTime $expires = DateTime.now.later( second => $.sessions-config.cookie-expiration );
            %!session-expiration{$session-id} = $expires;
        }
        my $session = $.sessions-store.fetch-session($session-id);
        $r.env<bailador.session-id> = $session-id;
        $r.env<bailador.session> = $session;
        return $session;
    }
    
    method store(Bailador::Response $r, Hash $env) {
        if $env<bailador.session-id>:exists and $env<bailador.session>:exists {
            my $session-id = $env<bailador.session-id>;
            my $session = $env<bailador.session>;
            Bailador::cookie($.sessions-config.cookie-name, $session-id, :path($.sessions-config.cookie-path));
            $.sessions-store.store-session($session-id, $session);
        }
    }
}
