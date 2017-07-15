use v6.c;

use Test;

use Bailador::App;
use Bailador::RouteHelper;
use Bailador::Template::Mustache;
use Bailador::Test;

plan 3;

class MyOwnWebApp is Bailador::App {
    submethod BUILD (|) {
        self.location( $?FILE.IO.dirname );
        self.renderer = Bailador::Template::Mustache.new;
        self.add_route: make-simple-route('GET', '/' => sub { self.template: 'simple.mustache', { 'foo' => 'bar' } });
    }
}

my $app = MyOwnWebApp.new.baile('p6w');

my $resp = get-psgi-response($app, 'GET',  '/');
is $resp[0], 200;
is-deeply $resp[1], ["Content-Type" => "text/html"];
ok $resp[2] ~~ /'a happy bar'\r?\n/;
