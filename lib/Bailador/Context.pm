use v6.c;

use Bailador::Request;
use Bailador::Response;

class Bailador::Context {
    has $!env;
    has Bailador::Request  $.request  = Bailador::Request.new;
    has Bailador::Response $.response = Bailador::Response.new;
    has Bool $.autorender is rw = True;

    method env {
        Proxy.new(
            FETCH => { $!env },
            STORE => -> $, $value {
                # reset response to default
                $!response.code    = 404;
                $!response.content = 'Not found';
                $!response.headers = {};
                $!response.headers<Content-Type> = 'text/html';
                $!response.cookies = ();
                $!env = $value;
                $!request.reset($!env);
                $!autorender = True;
            },
        );
    }
}
