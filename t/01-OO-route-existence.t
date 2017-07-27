use v6.c;

use Test;

use Bailador::RouteHelper;
use Bailador::Test;

plan 9 + 9 + 9;

class MyOwnWebApp is Bailador::App {
    submethod BUILD(|) {
        self.add_route: make-simple-route('GET','/foo' => sub { });
        self.add_route: make-simple-route('GET','/echo' => sub { return 'Echo: ' ~ (self.request.params<text> // '')});
        self.add_route: make-simple-route('GET','/echo2/:text' => sub ($text) { return 'Echo2: ' ~ join('-', $text,  (self.request.params<text> // ''), (self.request.params('body')<text> // ''), (self.request.params('query')<text> // ''))});
        self.add_route: make-simple-route('POST', '/bar' => sub { });
        self.add_route: make-simple-route('POST', '/echo3/:text' => sub ($text) { return 'Echo3: ' ~ join('-', $text,  (self.request.params<text> // ''), (self.request.params('body')<text> // ''), (self.request.params('query')<text> // ''))});


        # request methods when using GET requests
        self.add_route: make-simple-route('GET','/a' => sub { 'port=' ~ self.request.port });
        self.add_route: make-simple-route('GET','/b' => sub { 'request_uri=' ~ self.request.request_uri });
        self.add_route: make-simple-route('GET','/c' => sub { 'uri=' ~ self.request.uri });
        self.add_route: make-simple-route('GET','/d' => sub { 'path=' ~ self.request.path });
        self.add_route: make-simple-route('GET','/e' => sub { 'method=' ~ self.request.method });
        self.add_route: make-simple-route('GET','/f' => sub { join '-', self.request.is_get, self.request.is_post, self.request.is_put, self.request.is_delete, self.request.is_head, self.request.is_patch });
        self.add_route: make-simple-route('GET','/g' => sub { self.request.content_type });
        self.add_route: make-simple-route('GET','/h' => sub { self.request.content_length });
        self.add_route: make-simple-route('GET','/i' => sub { self.request.body });

        self.add_route: make-simple-route('POST', '/a' => sub { 'port=' ~ self.request.port });
        self.add_route: make-simple-route('POST', '/b' => sub { 'request_uri=' ~ self.request.request_uri });
        self.add_route: make-simple-route('POST', '/c' => sub { 'uri=' ~ self.request.uri });
        self.add_route: make-simple-route('POST', '/d' => sub { 'path=' ~ self.request.path });
        self.add_route: make-simple-route('POST', '/e' => sub { 'method=' ~ self.request.method });
        self.add_route: make-simple-route('POST', '/f' => sub { join '-', self.request.is_get, self.request.is_post, self.request.is_put, self.request.is_delete, self.request.is_head, self.request.is_patch });
        self.add_route: make-simple-route('POST', '/g' => sub { self.request.content_type });
        self.add_route: make-simple-route('POST', '/h' => sub { self.request.content_length });
        self.add_route: make-simple-route('POST', '/i' => sub { self.request.body });
    }
}

my $app = MyOwnWebApp.new.baile('p6w');

is-deeply get-psgi-response($app, 'GET', '/foo'),  [200, ["Content-Type" => "text/html"], ''],              'route GET /foo exists';
is-deeply get-psgi-response($app, 'POST', '/foo'), [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route POST /foo does not exist';
is-deeply get-psgi-response($app, 'POST', '/bar'), [200, ["Content-Type" => "text/html"], ''],              'route POST /bar exists';
is-deeply get-psgi-response($app, 'GET', '/bar'),  [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /bar does not exist';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/echo'),               [200, ["Content-Type" => "text/html"], 'Echo: '], 'echo';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/echo?text=bar'),      [200, ["Content-Type" => "text/html"], 'Echo: bar'], 'echo with text';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/echo2/foo'),          [200, ["Content-Type" => "text/html"], 'Echo2: foo---'], 'echo with text';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/echo2/foo?text=bar'), [200, ["Content-Type" => "text/html"], 'Echo2: foo-bar--bar'], 'echo with text';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:1234/echo3/foo?text=bar', 'text=zorg'), [200, ["Content-Type" => "text/html"], 'Echo3: foo-zorg-zorg-bar'], 'echo with text';

is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/a?text=bar'), [200, ["Content-Type" => "text/html"], 'port=1234'], 'port';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/b?text=bar'), [200, ["Content-Type" => "text/html"], 'request_uri=/b?text=bar'], 'request_uri';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/c?text=bar'), [200, ["Content-Type" => "text/html"], 'uri=/c?text=bar'], 'uri';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/d?text=bar'), [200, ["Content-Type" => "text/html"], 'path=/d'], 'path';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/e?text=bar'), [200, ["Content-Type" => "text/html"], 'method=GET'], 'method';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/f?text=bar'), [200, ["Content-Type" => "text/html"], 'True-False-False-False-False-False'], 'is';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/g?text=bar'), [200, ["Content-Type" => "text/html"], ''], 'content_type';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/h?text=bar'), [200, ["Content-Type" => "text/html"], ''], 'content_length';
is-deeply get-psgi-response($app, 'GET', 'http://127.0.0.1:1234/i?text=bar'), [200, ["Content-Type" => "text/html"], ''], 'body';

is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/a?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'port=9876'], 'port';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/b?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'request_uri=/b?text=bar'], 'requestn_uri';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/c?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'uri=/c?text=bar'], 'uri';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/d?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'path=/d'], 'path';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/e?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'method=POST'], 'method';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/f?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'False-True-False-False-False-False'], 'is';
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/g?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], ''], 'content_type';  # ???
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/h?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], ''], 'content_length';  # ???
is-deeply get-psgi-response($app, 'POST', 'http://127.0.0.1:9876/i?text=bar', 'text=foo'), [200, ["Content-Type" => "text/html"], 'text=foo'], 'body';
