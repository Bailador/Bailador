use v6.c;

use Test;

use Bailador::Test;

plan 3;

chdir 'examples';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "echo.pl6";

subtest {
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html;charset=UTF-8"], ""], 'route GET /';
    like $html, rx/\<form/;
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/echo?text=Hello+World');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html;charset=UTF-8"], "echo via GET: Hello World"], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'POST', '/echo', "text=Foo+Bar");
    is-deeply %data<response>, [200, ["Content-Type" => "text/html;charset=UTF-8"], "echo via POST: Foo Bar"], 'route GET /';
    is %data<err>, '';
}, '/';
