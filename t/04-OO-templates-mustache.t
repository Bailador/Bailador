use v6;
use Test;
use Bailador::App;
use Bailador::Test;

use Bailador::Template::Mustache;

plan 3;

class MyOwnWebApp is Bailador::App {
    submethod BUILD (|) {
        self.location = $?FILE.IO.dirname;
        self.renderer = Bailador::Template::Mustache.new;
        self.get: '/' => sub { self.template: 'simple.mustache', { 'foo' => 'bar' } }
    }
}

my $app = MyOwnWebApp.new;

my $resp = get-psgi-response($app, 'GET',  '/');
is $resp[0], 200;
is-deeply $resp[1], ["Content-Type" => "text/html"];
ok $resp[2] ~~ /'a happy bar'\r?\n/;
