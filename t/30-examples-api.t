use v6.c;

use JSON::Fast;
use Test;

use Bailador::Test;

plan 1;

chdir 'examples/api';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "api.pl6";

subtest {
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/');
    my $json_str = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "application/json"], ''], 'route GET /';
    is %data<err>, '';
    my %person := from-json $json_str;
    is-deeply %person, {
        name => 'Foo',
        id   => 42,
        courses => ['Perl', 'Web Development'],
    };
}, '/';
