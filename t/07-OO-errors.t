use Test;
use Bailador::App;
use Bailador::Test;

plan 3;

class MyOwnWebApp is Bailador::App {
    submethod BUILD(|) {

        self.get: '/die' => sub { die "oh no!" }
        self.get: '/fail' => sub { fail "oh no!" }
        self.get: '/exception' => sub { X::NYI.new(feature => 'NYI').throw }
    }
}

my $app = MyOwnWebApp.new;

is-deeply get-psgi-response($app, 'GET', '/die'),        [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles die';
is-deeply get-psgi-response($app, 'GET', '/fail'),       [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles fail';
is-deeply get-psgi-response($app, 'GET', '/exception'),  [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles thrown exception';
