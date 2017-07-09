use v6.c;

use Test;

use Bailador::Test;

plan 3;

chdir 'examples';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "err.pl6";

subtest {
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    like $html, rx:s/\<h2\>Welcome to Bailador\!\<\/h2\>/;
}, '/';


subtest {
    plan 4;

    my %data = run-psgi-request($app, 'GET', '/die');
    is %data<response>[0], 500;
    is-deeply %data<response>[1], ["Content-Type" => "text/html;charset=UTF-8"];
    is %data<response>[2], 'This is our custom 500 handler';
    like %data<err>, rx:s/This is an exception so you can see how it is handled/, 'stderr';
}, '/die';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/abc');
    is-deeply %data<response>, [404, ["Content-Type" => "text/html;charset=UTF-8"], 'This is our custom 404 handler'], 'route GET /abc';
    is %data<err>, '';
}, '/abc';

# vim: expandtab
# vim: tabstop=4
