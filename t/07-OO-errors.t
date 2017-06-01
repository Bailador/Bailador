use v6;
use Test;
use Bailador::App;
use Bailador::Test;

plan 6;

class MyOwnWebApp is Bailador::App {
    submethod BUILD(|) {

        self.get: '/die' => sub { die "oh no!" }
        self.get: '/fail' => sub { fail "oh no!" }
        self.get: '/exception' => sub { X::NYI.new(feature => 'NYI').throw }
    }
}

my $app = MyOwnWebApp.new;
my %data;

%data = run-psgi-request($app, 'GET', '/die');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles die';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request($app, 'GET', '/fail');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles fail';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request($app, 'GET', '/exception');
is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles thrown exception';
like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
