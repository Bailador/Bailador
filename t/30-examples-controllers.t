use v6.c;

use Test;

use Bailador::Test;

plan 3;

chdir 'examples/controllers';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "controllers.pl6";

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/');
    is-deeply %data<response>, [404, ["Content-Type" => "text/plain;charset=UTF-8"], "Not found"], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/data/abc');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'data for abc is '], 'route GET /';
    is %data<err>, '';
};

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/data');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    is $html, '{:bar(2), :foo(1)}';
};




# vim: expandtab
# vim: tabstop=4

