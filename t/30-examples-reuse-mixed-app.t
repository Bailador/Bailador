use v6.c;

use Test;

use Bailador::Test;

plan 4;

chdir 'examples/reuse';

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "bin/mixed_app.pl6";

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{<h1>Welcome to the root of MixedApp</h1>}], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/mixedapp');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Route /mixedapp}], 'route GET /';
    is %data<err>, '';
}, '/';

todo "Implement reusing applications";
subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/reuse');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{<h1>Welcome to root of the Shared App</h1>}], 'route GET /';
    is %data<err>, '';
}, '/';

todo "Implement reusing applications";
subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/reuse/sharedapp');
                is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Route /sharedapp of Shared App}], 'route GET /';
    is %data<err>, '';
}, '/';


chdir '../..';
