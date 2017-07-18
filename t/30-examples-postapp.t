use v6.c;

use Test;

use Bailador::Test;

plan 2;

chdir 'examples';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "postapp.pl6";

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html;charset=UTF-8"], "I am GET"], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'POST', '/', "text=Foo+Bar&answer=42");
    #note %data;
    is-deeply %data<response>, [200, ["Content-Type" => "application/octet-stream"], ["\{:answer(\"42\"), :text(\"Foo Bar\")}", Any, Any]], 'route POST /';
    is %data<err>, '';
}, '/';
