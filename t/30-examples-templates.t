use v6.c;

use Test;

use Bailador::Test;

plan 4;

chdir 'examples/templates';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "app.pl6";

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    ok $html.index('<h2>Welcome to Bailador templates example!</h2>') == 0, 'main page';
}, '/';

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/page');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /page';
    is %data<err>, '';
    ok $html.index('Page text') == 0, 'page';
}, '/';


subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/sub/page');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /page';
    is %data<err>, '';
    ok $html.index('Page in subdirectory') == 0, 'page';
}, '/';

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/sub/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /page';
    is %data<err>, '';
    ok $html.index('Root of subdirectory') == 0, 'page';
}, '/';


# vim: expandtab
# vim: tabstop=4

