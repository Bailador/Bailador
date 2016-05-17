use Test;
use Bailador;
use Bailador::Test;

plan 498;

get '/foo' => sub { "foo text" }
post '/bar' => sub { "peti bar" }

get '/baz' => sub { { foo => "bar", baz => 5 } }

get '/params/:foo'    => sub ($foo) { "a happy $foo" }
get /'/regexes/'(.+)/ => sub ($foo) { "a happy $foo" }

get '/header1' => sub {
    header("X-Test", "header1");
    "added header X-Test";
}

get '/header2' => sub {
    header("X-Again", "header2");
    "added header X-Again";
}

post '/utf8' => sub {
    request.params<text>;
}

is-deeply get-psgi-response('GET',  '/foo'),  [200, ["Content-Type" => "text/html"], 'foo text'],       'route GET /foo returns content';
is-deeply get-psgi-response('POST', '/bar'),  [200, ["Content-Type" => "text/html"], 'peti bar'],       'route POST /bar returns content';

is-deeply get-psgi-response('POST', '/foo'),  [404, ["Content-Type" => "text/html, charset=utf-8"], 'Not found'],      'route POST /foo not found';
is-deeply get-psgi-response('GET',  '/bar'),  [404, ["Content-Type" => "text/html, charset=utf-8"], 'Not found'],      'route GET /bar not found';

is-deeply get-psgi-response('GET',  '/params/bar'),   [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /params/bar returns content';
is-deeply get-psgi-response('GET',  '/regexes/bar'),  [200, ["Content-Type" => "text/html"], 'a happy bar'],       'route GET /regexes/bar returns content';

#todo 'returning complex structs NYI';
#response-content-is-deeply 'GET', '/baz', { foo => "bar", baz => 5 };

my $res = get-psgi-response('GET',  '/regexes/bar');
is $res[0], 200, 'status code';
is-deeply $res[1], ["Content-Type" => "text/html"], 'header';

todo 'returning complex structs NYI';
is-deeply $res[2], { foo => "bar", baz => 5 }; # this should be json, right? 

is-deeply get-psgi-response('GET', '/header1'), [ 200, ["X-Test" => "header1", "Content-Type" => "text/html" ], "added header X-Test" ], 'ROUTE GET /header1 sends an extra header';

is-deeply get-psgi-response('GET',  '/header2'),  [ 200, ["X-Again" => "header2", "Content-Type" => "text/html"], 'added header X-Again' ], 'ROUTE GET /header2 sends an extra and does not include headers from previous requests';

my @hex = ('A'..'F', 'a'..'f', 0..9).flat;
for @hex -> $first {
    for @hex -> $second {
        lives-ok { get-psgi-response('POST', 'http://127.0.0.1/utf8',
            'text=%' ~ $first ~ $second); }, "decoding \%$first$second works";
    }
}

{
my $res0 = get-psgi-response('POST', 'http://127.0.0.1/utf8', 'text=%C3%86');
my $res1 = get-psgi-response('POST', 'http://127.0.0.1/utf8', 'text=%C6');
my $res2 = get-psgi-response('POST', 'http://127.0.0.1/utf8', 'text=%C3%86%C6');

is $res0[2], chr(198), 'utf8 encoding was correct';
is $res1[2], chr(198), 'fallback encoding was correct';
is $res2[2], chr(0xC3) ~ chr(0x86) ~ chr(0xC6), 'non-UTF8 encoding caused a fallback';
}
