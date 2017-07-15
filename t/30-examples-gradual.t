use v6.c;

use Test;

use Bailador::Test;

plan 6;

chdir 'examples/gradual';
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
    like $html, rx:s/\<h1\>Main page \- from template\.\<\/h1\>/;
}, '/';


subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/foo');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'Foo from route'], 'route GET /';
    is %data<err>, '';
}, '/foo';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/bar');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "Bar from template\n"], 'route GET /bar';
    is %data<err>, '';
}, '/bar';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/qux');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "Qux from route"], 'route GET /qux';
    is %data<err>, '';
}, '/qux';



subtest {
    plan 4;
    my %data = run-psgi-request($app, 'GET', '/xyz');
    is %data<response>[0], 404;
    is-deeply %data<response>[1], ["Content-Type" => "text/plain;charset=UTF-8"];
    is-deeply %data<response>[2], 'Not found';
    is %data<err>, '', 'stderr';
}, '/xyz';


subtest {
    plan 4;
    my %data = run-psgi-request($app, 'GET', '/robots.txt');
    is %data<response>[0], 200;
    is-deeply %data<response>[1], ["Content-Type" => "text/plain;charset=UTF-8"];
    is %data<response>[2].decode('utf-8'), "Disallow: /media/*\n";
    is %data<err>, '', 'stderr';
}, '/xyz';



# vim: expandtab
# vim: tabstop=4
