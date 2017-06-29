use v6.c;

use Test;

use Bailador::Test;

plan 2;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
my $app = EVALFILE "examples/postapp.pl6";

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "I am GET"], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'POST', '/', "text=Foo+Bar&answer=42");
    #note %data;
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ["\{:answer(\"42\"), :text(\"Foo Bar\")}", Any, Any]], 'route POST /';
    is %data<err>, '';
}, '/';
