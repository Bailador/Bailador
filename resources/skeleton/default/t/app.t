use v6.c;
use Test;
use Bailador::Test;

plan 1;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "bin/app.pl6";

subtest {
    plan 4;
    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    like $html, rx:s/\<h1\>Bailador App\<\/h1\>/;
    like $html, rx:s/Version 0\.0\.1/;
}, '/';
