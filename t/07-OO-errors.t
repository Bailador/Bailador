use v6.c;

use Test;

use Bailador::App;
use Bailador::RouteHelper;
use Bailador::Test;

plan 6;

class MyOwnWebApp is Bailador::App {
    submethod BUILD(|) {

        self.add_route: make-simple-route('GET','/die' => sub { die "oh no!" });
        self.add_route: make-simple-route('GET','/fail' => sub { fail "oh no!" });
        self.add_route: make-simple-route('GET','/exception' => sub { X::NYI.new(feature => 'NYI').throw });
    }
}

my $app = MyOwnWebApp.new.baile('p6w');
my %data;

%data = run-psgi-request($app, 'GET', '/die');
is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles die';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request($app, 'GET', '/fail');
is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles fail';
like %data<err>, rx:s/oh no\!/, 'stderr';

%data = run-psgi-request($app, 'GET', '/exception');
is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles thrown exception';
like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
