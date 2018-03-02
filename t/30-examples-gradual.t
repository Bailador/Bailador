use v6.c;

use Test;

use Bailador::Test;

plan 9;

chdir 'examples/gradual';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "app.pl6";

# test 1
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    subtest {
        plan 3;
        my %data = run-psgi-request($app, 'GET', '/');
        my $html = %data<response>[2];
        %data<response>[2] = '';
        is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
        is %data<err>, '';
        like $html, rx:s/\<h1\>Main page \- from template\.\<\/h1\>/;
    }, '/';
}

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/foo');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'Foo from route'], 'route GET /';
    is %data<err>, '';
}, '/foo';

# test 3
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    subtest {
        plan 2;
        my %data = run-psgi-request($app, 'GET', '/bar');
        is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "Bar from template\n"], 'route GET /bar';
        is %data<err>, '';
    }, '/bar';
}

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

# test 7
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    subtest {
        plan 2;
        my %data = run-psgi-request($app, 'GET', '/cakes/carrot');
        is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "Carrot Cake\n"], 'route GET /cakes/carrot';
        is %data<err>, '';
    }
}


# test 8
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    subtest {
        plan 2;
        my %data = run-psgi-request($app, 'GET', '/cakes/');
        is-deeply %data<response>, [200, ["Content-Type" => "text/html"], "Root Cake\n"], 'route GET /cakes/';
        is %data<err>, '';
    };
}

subtest {
    plan 2 + 7;

    my %data = run-psgi-request($app, 'GET', '/sitemap.xml');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/xml"], ''], 'route GET /sitemap.xml';
    is %data<err>, '';

    for (
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
        '<loc>http://0.0.0.0:1234/bar.html</loc>',
        '<loc>http://0.0.0.0:1234/foo.html</loc>',
        '<loc>http://0.0.0.0:1234/</loc>',
        '<loc>http://0.0.0.0:1234/cakes/carrot.html</loc>',
        '<loc>http://0.0.0.0:1234/cakes/</loc>',
    ) -> $url {
        ok $html.index($url) > -1, $url;
    }
};



# vim: expandtab
# vim: tabstop=4
