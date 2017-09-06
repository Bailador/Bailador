use v6.c;

use Test;

use Bailador::Test;

plan 1;

chdir 'examples/request';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "request.pl6";

subtest {
    plan 6;

    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    ok $html.index('Show the parameters of the request object') > 0;
    ok $html.index('<tr><td>port</td><td>1234</td></tr>') > 0, 'port';
    ok $html.index('<tr><td>server</td><td>0.0.0.0</td></tr>') > 0, 'server';
    ok $html.index('<tr><td>url_root</td><td>http://0.0.0.0:1234</td></tr>') > 0, 'url_root';
    #diag $html;
}, '/';

# vim: expandtab
# vim: tabstop=4
