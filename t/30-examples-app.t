use v6;
use Test;
use Bailador::Test;

plan 2;

%*ENV<BAILADOR_TESTING> = "yes";

my $app = EVALFILE "examples/app.pl6";

subtest {
    plan 1;
	is-deeply get-psgi-response($app, 'GET', '/'), [200, ["Content-Type" => "text/html"], 'hello world'], 'route GET / exists';
}, '/';

subtest {
	plan 2;
	my %data = run-psgi-request($app, 'GET', '/die');
	is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET /die dies';
    like %data<err>, rx:s/This is an exception so you can see how it is handled/, 'stderr';
}, '/die';

# vim: expandtab
# vim: tabstop=4
