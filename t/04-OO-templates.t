use Test;
use Bailador::App;
use Bailador::Test;

plan 3;

class MyOwnWebApp is Bailador::App {
    submethod BUILD (|) {
        self.location = $?FILE.IO.dirname;
        self.get: '/' => sub { self.template: 'simple.tt', 'bar' }
    }
}

my $app = MyOwnWebApp.new;

my $resp = get-psgi-response($app, 'GET',  '/');
is $resp[0], 200;
is-deeply $resp[1], ["Content-Type" => "text/html"];
ok $resp[2] ~~ /'a happy bar'\r?\n/;
