use v6.c;

use Bailador::Request;
use Bailador::Response;

class Bailador::Context {
    has $!env;
    has Bailador::Request  $.request  = Bailador::Request.new;
    has Bailador::Response $.response = Bailador::Response.new;
    has Bool $.autorender is rw = True;

    method env is rw {
        Proxy.new(
            FETCH => { $!env },
            STORE => -> $, $value {
                # reset response to default
                $!response.code    = 200;
                $!response.content = '';
                $!response.headers = {};
                $!response.cookies = ();
                $!env = $value;
                $!request.reset($!env);
                $!autorender = True;
            },
        );
    }
}
