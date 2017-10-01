use v6.c;

use Test;

use Bailador::Test;

plan 3;

chdir 'examples/reuse';

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "bin/inherit_app.pl6";

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{<h1>Welcome to root of the Shared App</h1>}], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/sharedapp');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Route /sharedapp of Shared App}], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/inheritapp');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Route /inheritapp}], 'route GET /';
    is %data<err>, '';
}, '/';

chdir '../..';
