use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 14;

get '/cook1' => sub {
    cookie("flavour", "chocolate");
    "cookie test #1";
}

get '/cook2' => sub {
    cookie("flavour", "chocolate", domain => "example.com");
    "cookie test #2";
}

get '/cook3' => sub {
    cookie("flavour", "chocolate", path => "/test");
    "cookie test #3";
}

get '/cook4' => sub {
    cookie("flavour", "chocolate", path => "/test", domain => "example.com");
    "cookie test #4";
}

get '/cook5' => sub {
    cookie("flavour", "chocolate", expires => DateTime.new("2021-06-09T01:18:14-09"));
    "cookie test #5";
}

get '/rfc1' => sub {
    cookie("SID", "31d4d96e407aad42");
    "rfc";
}

get '/rfc2' => sub {
    cookie("SID", "31d4d96e407aad42", path=> "/", domain => "example.com");
    "rfc";
}
get '/rfc3' => sub {
    cookie("SID", "31d4d96e407aad42", path=> "/", :secure, :http-only);
    "rfc";
}

get '/rfc4' => sub {
    cookie("lang", "", expires => DateTime.new("1994-11-06T08:49:37"));
    "rfc";
}

get '/wiki1' => sub {
    cookie("LSID", "DQAAAKEaem_vYg", path => "/accounts", expires => DateTime.new("2021-01-13T22:23:01"), :secure, :http-only);
    "wikipedia";
}

get '/wiki2' => sub {
    cookie("SSID", "Ap4P.GTEq", domain => "foo.com", path => "/", expires => DateTime.new("2021-01-13T22:23:01"), :secure, :http-only);
    "wikipedia";
}

get '/multi1' => sub {
    cookie("enwikiUserID", "127001", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :secure, :http-only);
    cookie("enwikiUserName", "localhost", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :secure, :http-only);
    cookie("forceHTTPS", "true", expires => DateTime.new("2015-10-15T15:12:40"), path => '/', :http-only);
    "multiple";
}

get '/escape1' => sub {
    cookie("key", "value;", :secure);
    "escape";
}

get '/escape2' => sub {
    cookie("the=key", "value", path => "/");
    "escape";
}

# Call baile just once
my $p6w-app = baile('p6w');

is-deeply get-psgi-response($p6w-app, 'GET', '/cook1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate"], "cookie test #1" ], 'ROUTE GET /cook1 sets a cookie';

is-deeply get-psgi-response($p6w-app, 'GET', '/cook2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Domain=example.com"], "cookie test #2" ], 'ROUTE GET /cook2 sets a cookie with a domain';

is-deeply get-psgi-response($p6w-app, 'GET', '/cook3'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Path=/test"], "cookie test #3" ], 'ROUTE GET /cook3 sets a cookie with a path';

is-deeply get-psgi-response($p6w-app, 'GET', '/cook4'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Path=/test; Domain=example.com"], "cookie test #4" ], 'ROUTE GET /cook4 sets a cookie with a path and domain';

is-deeply get-psgi-response($p6w-app, 'GET', '/cook5'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "flavour=chocolate; Expires=Wed, 09 Jun 2021 10:18:14 GMT"], "cookie test #5" ], 'ROUTE GET /cook5 sets a cookie with an expiry';

is-deeply get-psgi-response($p6w-app, 'GET', '/rfc1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42"], "rfc" ], 'ROUTE GET /rfc1 sets a cookie like RFC 6265 page 6';

is-deeply get-psgi-response($p6w-app, 'GET', '/rfc2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42; Path=/; Domain=example.com"], "rfc" ], 'ROUTE GET /rfc2 sets a cookie with path and domain like RFC 6265 page 6';

is-deeply get-psgi-response($p6w-app, 'GET', '/rfc3'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly"], "rfc" ], 'ROUTE GET /rfc3 sets a secure httponly cookie with path like RFC 6265 page 6';

is-deeply get-psgi-response($p6w-app, 'GET', '/rfc4'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "lang=; Expires=Sun, 06 Nov 1994 08:49:37 GMT"], "rfc" ], 'ROUTE GET /rfc4 sets a cookie with with no value like RFC 6265 page 7';

is-deeply get-psgi-response($p6w-app, 'GET', '/wiki1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "LSID=DQAAAKEaem_vYg; Path=/accounts; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly"], "wikipedia" ], 'ROUTE GET /wiki1 sets a cookie like an example from the HTTP cookie wikipedia article';

is-deeply get-psgi-response($p6w-app, 'GET', '/wiki2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => "SSID=Ap4P.GTEq; Path=/; Domain=foo.com; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly"], "wikipedia" ], 'ROUTE GET /wiki2 sets a cookie with all parameters like an example from the HTTP cookie wikipedia article';

is-deeply get-psgi-response($p6w-app, 'GET', '/multi1'),
    [ 200,
        [
            "Content-Type" => "text/html",
            "Set-Cookie" => "enwikiUserID=127001; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; Secure; HttpOnly",
            "Set-Cookie" => "enwikiUserName=localhost; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; Secure; HttpOnly",
            "Set-Cookie" => "forceHTTPS=true; Path=/; Expires=Thu, 15 Oct 2015 15:12:40 GMT; HttpOnly"
        ], "multiple"
    ], 'ROUTE GET /multi1 sets multiple cookies';

is-deeply get-psgi-response($p6w-app, 'GET', '/escape1'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => 'key=value%3B; Secure'], "escape" ], 'ROUTE GET /escape1 sends a cookie with a URI encoded value';

is-deeply get-psgi-response($p6w-app, 'GET', '/escape2'), [ 200, ["Content-Type" => "text/html", "Set-Cookie" => 'the%3Dkey=value; Path=/'], "escape" ], 'ROUTE GET /escape2 sends a cookie with a URI encoded key';
