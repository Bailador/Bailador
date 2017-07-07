use v6.c;

use Test;

use Bailador::App;
use Bailador::RouteHelper;
use Bailador::Test;

plan 14;

class MyOwnWebApp is Bailador::App {
    submethod BUILD (|) {

        self.add_route: make-simple-route('GET','/cook1' => sub {
            self.response.cookie("flavour", "chocolate");
            "cookie test #1";
        });

        self.add_route: make-simple-route('GET','/cook2' => sub {
            self.response.cookie("flavour", "chocolate", domain => "example.com");
            "cookie test #2";
        });

        self.add_route: make-simple-route('GET','/cook3' => sub {
            self.response.cookie("flavour", "chocolate", path => "/test");
            "cookie test #3";
        });

        self.add_route: make-simple-route('GET','/cook4' => sub {
            self.response.cookie("flavour", "chocolate", path => "/test", domain => "example.com");
            "cookie test #4";
        });

        self.add_route: make-simple-route('GET','/cook5' => sub {
            self.response.cookie("flavour", "chocolate", expires => DateTime.new("2021-06-09T01:18:14-09"));
            "cookie test #5";
        });

        self.add_route: make-simple-route('GET','/rfc1' => sub {
            self.response.cookie("SID", "31d4d96e407aad42");
            "rfc";
        });

        self.add_route: make-simple-route('GET','/rfc2' => sub {
            self.response.cookie("SID", "31d4d96e407aad42", path=> "/", domain => "example.com");
            "rfc";
        });
        self.add_route: make-simple-route('GET','/rfc3' => sub {
            self.response.cookie("SID", "31d4d96e407aad42", path=> "/", :secure, :http-only);
            "rfc";
        });

        self.add_route: make-simple-route('GET','/rfc4' => sub {
            self.response.cookie("lang", "", expires => DateTime.new("1994-11-06T08:49:37"));
            "rfc";
        });

        self.add_route: make-simple-route('GET','/wiki1' => sub {
            self.response.cookie("LSID", "DQAAAKEaem_vYg", path => "/accounts", expires => DateTime.new("2021-01-13T22:23:01"), :secure, :http-only);
            "wikipedia";
        });

        self.add_route: make-simple-route('GET','/wiki2' => sub {
            self.response.cookie("SSID", "Ap4P.GTEq", domain => "foo.com", path => "/", expires => DateTime.new("2021-01-13T22:23:01"), :secure, :http-only);
            "wikipedia";
        });

        self.add_route: make-simple-route('GET','/multi1' => sub {
            self.response.cookie("enwikiUserID", "127001", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :secure, :http-only);
            self.response.cookie("enwikiUserName", "localhost", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :secure, :http-only);
            self.response.cookie("forceHTTPS", "true", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :http-only);
            "multiple";
        });

        self.add_route: make-simple-route('GET','/escape1' => sub {
            self.response.cookie("key", "value;", :secure);
            "escape";
        });

        self.add_route: make-simple-route('GET','/escape2' => sub {
            self.response.cookie("the=key", "value", path => "/");
            "escape";
        });
    }
}

my $app = MyOwnWebApp.new;


is-deeply get-psgi-response($app, 'GET', '/cook1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate"], "cookie test #1" ], 'ROUTE GET /cook1 sets a cookie';

is-deeply get-psgi-response($app, 'GET', '/cook2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Domain=example.com"], "cookie test #2" ], 'ROUTE GET /cook2 sets a cookie with a domain';

is-deeply get-psgi-response($app, 'GET', '/cook3'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Path=/test"], "cookie test #3" ], 'ROUTE GET /cook3 sets a cookie with a path';

is-deeply get-psgi-response($app, 'GET', '/cook4'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Path=/test; Domain=example.com"], "cookie test #4" ], 'ROUTE GET /cook4 sets a cookie with a path and domain';

is-deeply get-psgi-response($app, 'GET', '/cook5'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Expires=Wed, 09 Jun 2021 10:18:14 GMT"], "cookie test #5" ], 'ROUTE GET /cook5 sets a cookie with an expiry';

is-deeply get-psgi-response($app, 'GET', '/rfc1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42"], "rfc" ], 'ROUTE GET /rfc1 sets a cookie like RFC 6265 page 6';

is-deeply get-psgi-response($app, 'GET', '/rfc2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42; Path=/; Domain=example.com"], "rfc" ], 'ROUTE GET /rfc2 sets a cookie with path and domain like RFC 6265 page 6';

is-deeply get-psgi-response($app, 'GET', '/rfc3'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly"], "rfc" ], 'ROUTE GET /rfc3 sets a secure httponly cookie with path like RFC 6265 page 6';

is-deeply get-psgi-response($app, 'GET', '/rfc4'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "lang=; Expires=Sun, 06 Nov 1994 08:49:37 GMT"], "rfc" ], 'ROUTE GET /rfc4 sets a cookie with with no value like RFC 6265 page 7';

is-deeply get-psgi-response($app, 'GET', '/wiki1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "LSID=DQAAAKEaem_vYg; Path=/accounts; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly"], "wikipedia" ], 'ROUTE GET /wiki1 sets a cookie like an example from the HTTP cookie wikipedia article';

is-deeply get-psgi-response($app, 'GET', '/wiki2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SSID=Ap4P.GTEq; Path=/; Domain=foo.com; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly"], "wikipedia" ], 'ROUTE GET /wiki2 sets a cookie with all parameters like an example from the HTTP cookie wikipedia article';

is-deeply get-psgi-response($app, 'GET', '/multi1'),
    [ 200,
        [
            "Content-Type" => "text/html",
            "Set-Cookie" => "enwikiUserID=127001; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; Secure; HttpOnly",
            "Set-Cookie" => "enwikiUserName=localhost; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; Secure; HttpOnly",
            "Set-Cookie" => "forceHTTPS=true; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; HttpOnly"
        ], "multiple"
    ], 'ROUTE GET /multi1 sets multiple cookies';

is-deeply get-psgi-response($app, 'GET', '/escape1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => 'key=value%3B; Secure'], "escape" ], 'ROUTE GET /escape1 sends a cookie with a URI encoded value';

is-deeply get-psgi-response($app, 'GET', '/escape2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => 'the%3Dkey=value; Path=/'], "escape" ], 'ROUTE GET /escape2 sends a cookie with a URI encoded key';
