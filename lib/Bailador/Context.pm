use Bailador::Request;
use Bailador::Response;

class Bailador::Context {
    has $!env;
    has Bailador::Request  $.request  = Bailador::Request.new;
    has Bailador::Response $.response = Bailador::Response.new;

    method env {
        Proxy.new(
            FETCH => { $!env },
            STORE => -> $, $value {
                # reset response to default
                $!response.code    = 404;
                $!response.content = 'Not found';
                $!response.headers<Content-Type> = 'text/html';
                $!response.cookies = ();
                $!request.env = $!env = $value;
            },
        );
    }
}
