use Test;
use Bailador;
use Bailador::Test;

plan 11;

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

is-deeply get-psgi-response('GET',  '/foo'),  [200, ["Content-Type" => "text/html"], 'foo text'],       'route GET /foo returns content';
is-deeply get-psgi-response('POST', '/bar'),  [200, ["Content-Type" => "text/html"], 'peti bar'],       'route POST /bar returns content';

is-deeply get-psgi-response('POST', '/foo'),  [404, ["Content-Type" => "text/html"], 'Not found'],      'route POST /foo not found';
is-deeply get-psgi-response('GET',  '/bar'),  [404, ["Content-Type" => "text/html"], 'Not found'],      'route GET /bar not found';

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
