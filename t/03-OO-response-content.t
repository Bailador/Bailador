use v6.c;

use Test;

use Bailador::App;
use Bailador::Test;

plan 498;

class MyOwnWebApp is Bailador::App {
    submethod BUILD(|) {
        self.get: '/foo' => sub { "foo text" }
        self.post: '/bar' => sub { "peti bar" }

        self.get: '/baz' => sub { { foo => "bar", baz => 5 } }

        self.get: '/params/:foo'    => sub ($foo) { "a happy $foo" }
        self.get: /'/regexes/'(.+)/ => sub ($foo) { "a happy $foo" }

        self.get: '/header1' => sub {
            self.response.headers{"X-Test"} = "header1";
            "added header X-Test";
        }

        self.get: '/header2' => sub {
            self.response.headers{"X-Again"} = "header2";
            "added header X-Again";
        }

        self.post: '/utf8' => sub {
            self.request.params<text>;
        }
    }
}
my $app = MyOwnWebApp.new;

is-deeply get-psgi-response($app, 'GET',  '/foo'),  [200, ["Content-Type" => "text/html"], 'foo text'],       'route GET /foo returns content';
is-deeply get-psgi-response($app, 'POST', '/bar'),  [200, ["Content-Type" => "text/html"], 'peti bar'],       'route POST /bar returns content';

is-deeply get-psgi-response($app, 'POST', '/foo'),  [404, ["Content-Type" => "text/html;charset=UTF-8"], 'Not found'],      'route POST /foo not found';
is-deeply get-psgi-response($app, 'GET',  '/bar'),  [404, ["Content-Type" => "text/html;charset=UTF-8"], 'Not found'],      'route GET /bar not found';

is-deeply get-psgi-response($app, 'GET',  '/params/bar'),   [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /params/bar returns content';
is-deeply get-psgi-response($app, 'GET',  '/regexes/bar'),  [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /regexes/bar returns content';

#todo 'returning complex structs NYI';
#response-content-is-deeply 'GET', '/baz', { foo => "bar", baz => 5 };

my $res = get-psgi-response($app, 'GET',  '/regexes/bar');
is $res[0], 200, 'status code';
is-deeply $res[1], ["Content-Type" => "text/html"], 'header';

todo 'returning complex structs NYI';
is-deeply $res[2], { foo => "bar", baz => 5 }; # this should be json, right?

is-deeply get-psgi-response($app, 'GET', '/header1'), [ 200, ["X-Test" => "header1", "Content-Type" => "text/html" ], "added header X-Test" ], 'ROUTE GET /header1 sends an extra header';

is-deeply get-psgi-response($app, 'GET',  '/header2'),  [ 200, ["X-Again" => "header2", "Content-Type" => "text/html"], 'added header X-Again' ], 'ROUTE GET /header2 sends an extra and does not include headers from previous requests';

my @hex = ('A'..'F', 'a'..'f', 0..9).flat;
for @hex -> $first {
    for @hex -> $second {
        lives-ok { get-psgi-response($app, 'POST', 'http://127.0.0.1/utf8',
            'text=%' ~ $first ~ $second); }, "decoding \%$first$second works";
    }
}

{
my $res0 = get-psgi-response($app, 'POST', 'http://127.0.0.1/utf8', 'text=%C3%86');
my $res1 = get-psgi-response($app, 'POST', 'http://127.0.0.1/utf8', 'text=%C6');
my $res2 = get-psgi-response($app, 'POST', 'http://127.0.0.1/utf8', 'text=%C3%86%C6');

is $res0[2], chr(198), 'utf8 encoding was correct';
is $res1[2], chr(198), 'fallback encoding was correct';
is $res2[2], chr(0xC3) ~ chr(0x86) ~ chr(0xC6), 'non-UTF8 encoding caused a fallback';
}
