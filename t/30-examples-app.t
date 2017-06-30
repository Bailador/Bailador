use v6.c;

use Test;

use Bailador::Test;

plan 14;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
my $app = EVALFILE "examples/app.pl6";

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
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/style.css');
    my $css = %data<response>[2].decode;
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/css"], ""], 'route GET /style.css';
    is %data<err>, '';
    is $css, qq{body { margin: 0px; }\n};
}, 'testcase for Bailador::Route::StaticFile';


subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/red');
    is-deeply %data<response>, [302, ["Content-Type" => "text/html", :Location("/index.html")], "Not found"], 'route GET /red';
    is %data<err>, '';
}, '/red';

subtest {
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/die');
    is %data<response>[0], 500;
    is-deeply %data<response>[1], ["Content-Type" => "text/html;charset=UTF-8"];
    like %data<err>, rx:s/This is an exception so you can see how it is handled/, 'stderr';
}, '/die';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/about');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'about me'], 'route GET /about';
    is %data<err>, '';
}, '/about';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/hello/Foo');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'Hello Foo!'], 'route GET /hello/Foo';
    is %data<err>, '';
}, '/hello/Foo';

todo "See https://github.com/Bailador/Bailador/issues/178";
subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/hello/Foo.html');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'Hello Foo.html!'], 'route GET /hello/Foo.html';
    is %data<err>, '';
}, '/hello/foo.html';


subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/abc');
    is-deeply %data<response>, [404, ["Content-Type" => "text/html;charset=UTF-8"], 'Not found'], 'route GET /abc';
    is %data<err>, '';
}, '/abc';

#todo 'See https://github.com/Bailador/Bailador/issues/177';
subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/hello/Foo/Bar');
    is-deeply %data<response>, [404, ["Content-Type" => "text/html;charset=UTF-8"], 'Not found'], 'route GET /hello/Foo/Bar';
    is %data<err>, '';
}, '/hello/Foo/Bar';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/def/egy/ketto');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Hello 'egy' and 'ketto'!}], 'route GET /def/egy/ketto';
    is %data<err>, '';
}, '/def/egy/ketto';


subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/foo-and-more');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'regexes! I got -and-more'], 'route GET /foo-and-more';
    is %data<err>, '';
}, '/foo-and-more';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/foo/and/more');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'regexes! I got /and/more'], 'route GET /foo/and/more';
    is %data<err>, '';
}, '/foo/and/more';


subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/two-parts');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'two and parts'], 'route GET /two-parts';
    is %data<err>, '';
}, '/two-parts';

#subtest {
#    plan 2;
#    my %data = run-psgi-request($app, 'GET', '/template/Camelia');
#    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /template/Camelia';
#    is %data<err>, '';
#}, '/template/Camelia';

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'HEAD', '/');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route HEAD /';
    is %data<err>, '';
}, '/';


# vim: expandtab
# vim: tabstop=4
