use Test;
use Bailador;
use Bailador::Test;

plan 27;

my %env = (
        'psgi.url_scheme'    => 'http',
        REQUEST_METHOD       => 'GET',
        SCRIPT_NAME          => '/foo',
        PATH_INFO            => '/bar/baz',
        REQUEST_URI          => '/foo/bar/baz',
        QUERY_STRING         => 'foo=42&bar=12&bar=13&bar=14',
        SERVER_NAME          => 'localhost',
        SERVER_PORT          => 5000,
        SERVER_PROTOCOL      => 'HTTP/1.1',
        REMOTE_ADDR          => '127.0.0.1',
        HTTP_X_FORWARDED_FOR      => '127.0.0.2',
        HTTP_X_FORWARDED_HOST     => 'secure.frontend',
        HTTP_X_FORWARDED_PROTOCOL => 'https',
        REMOTE_HOST          => 'localhost',
        HTTP_USER_AGENT      => 'Mozilla',
        REMOTE_USER          => 'sukria',
        HTTP_COOKIE          => 'cookie.a=foo=bar; cookie.b=1234abcd; no.value.cookie',
);

ok my $req = Bailador::Request.new(env => %env), 'request object created';
isa-ok $req, Bailador::Request;

# testing accessors';
is $req.user_agent,            'Mozilla';
is $req.address,               '127.0.0.1';
is $req.remote_host,           'localhost';
is $req.protocol,              'HTTP/1.1';
is $req.port,                  5000;
is $req.request_uri,           '/foo/bar/baz';
is $req.uri,                   '/foo/bar/baz';
is $req.user,                  'sukria';
is $req.script_name,           '/foo';
skip '$req.scheme not implemented yet', 1;
# is $req.scheme,                'http';
skip '$req.secure not implemented yet', 1;
#ok( !$req.secure );
is $req.referer,     Any, 'referer is not defined';
is $req.method,     'GET', 'got the right method';
ok $req.is_get,     'is_get() is true for GET request';
ok !$req.is_post,   'is_post() is false for GET request';
ok !$req.is_put,    'is_put() is false for GET request';
ok !$req.is_delete, 'is_delete() is false for GET request';
ok !$req.is_patch,  'is_patch() is false for GET request';
ok !$req.is_head,   'is_head() is false for GET request';

# testing request parameters
#FIXME: is-deeply $req.params, (foo => '42', bar => ['12', '13', '14']), 'request parameters match';
my %params = $req.params;
is %params{'foo'}, 42, 'Str param properly received';
my $bar = %params{'bar'};
is $bar.elems, 3, '3 elements in "bar"';
is $bar[0], '12', 'first element looks right';
is $bar[1], '13', 'second element looks right';
is $bar[2], '14', 'third element looks right';

# testing cookies on the request
is $req.cookies.elems, 3, "multiple cookies extracted";
