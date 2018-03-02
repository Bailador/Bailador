use v6.c;

use Test;

use Bailador::Test;

plan 7;

chdir 'examples/class';
%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "class_app.pl6";

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    like $html, rx:s/\<h1\>Welcome to Bailador\!\<\/h1\>/;
}, '/';


subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/param/qqrq');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'Code: qqrq'], 'route GET /param/qqrq';
    is %data<err>, '';
};


subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/params/one/two');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Params: 'one' 'two'}], 'route GET /param/qqrq';
    is %data<err>, '';
};


subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/params/one/two');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Params: 'one' 'two'}], 'route GET /params/one/two';
    is %data<err>, '';
};

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/from');
    is-deeply %data<response>, [302, ["Location" => "/to"], ''], 'route GET /from';
    is %data<err>, '';
};

subtest {
    plan 2;

    my %data = run-psgi-request($app, 'GET', '/to');
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], q{Arrived to.}], 'route GET /to';
    is %data<err>, '';
};

# test 7
if $*DISTRO.is-win {
    skip "Skipping failing Windows test...";
}
else {
    subtest {
        plan 3;

        my %data = run-psgi-request($app, 'GET', '/tmpl/xyz');
        my $html = %data<response>[2];
        %data<response>[2] = '';
        is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
        like $html, rx:s/\<title\>A greeting for xyz\<\/title\>/;
        is %data<err>, '';
    }
}
