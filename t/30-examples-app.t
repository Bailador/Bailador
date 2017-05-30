use v6;
use Test;
use Bailador::Test;

plan 1;

%*ENV<BAILADOR_TESTING> = "yes";

my $app = EVALFILE "examples/app.pl6";

is-deeply get-psgi-response($app, 'GET', '/'),  [200, ["Content-Type" => "text/html"], 'hello world'],   'route GET / exists';

