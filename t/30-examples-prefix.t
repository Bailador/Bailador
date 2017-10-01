use v6.c;

use Test;

use Bailador::Test;

plan 4;

chdir 'examples/prefix';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "prefix.pl6";

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/plain');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'plain'], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/books/');
    is-deeply %data<response>, [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /';
    is %data<err>, '';
}, '/';


subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/books/fiction');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], '/books/fiction'], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/books/childrens/alpha');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'alpha'], 'route GET /';
    is %data<err>, '';
}, '/';


# vim: expandtab
# vim: tabstop=4

