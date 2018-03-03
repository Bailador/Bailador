use v6.c;

use Test;

use Bailador::Test;

plan 2;

if $*DISTRO.is-win {
    skip-rest "The following subtests fail to run on Windows.";
    exit;
}

chdir 'examples/layout';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE 'bin/app.pl6';

subtest {
    plan 5;

    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ['Content-Type' => 'text/html'], ''], 'route GET /';
    is %data<err>, '';
    ok index($html, '<h1>Hello Layout</h1>') !=== Nil;
    ok index($html, '<h2>Main.tt file</h2>') !=== Nil;
    ok index($html, '<h3>This is the default layout.</h3>') !=== Nil;

}, '/';

subtest {
    plan 5;

    my %data = run-psgi-request($app, 'GET', '/other');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    #note $html;
    is-deeply %data<response>, [200, ['Content-Type' => 'text/html'], ''], 'route GET /other';
    is %data<err>, '';
    ok index($html, '<h1>Using Other Layout</h1>') !=== Nil;
    ok index($html, '<h2>Main.tt file</h2>') !=== Nil;
    ok index($html, '<h3>This is the Other layout.</h3>') !=== Nil;
}, '/';
