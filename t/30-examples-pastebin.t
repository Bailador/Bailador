use v6;
use Test;
use Bailador::Test;
use File::Directory::Tree;

plan 2;

# the templating system needs relative path
chdir "examples";
die "Directory examples/data exists. Remove it before running the test." if 'data'.IO.e;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
my $app = EVALFILE "pastebin.pl6";

subtest {
    plan 2;
    my %data = run-psgi-request($app, 'GET', '/');
    my $main_html = qq{<form action='/new_paste' method='post'>
\t<textarea name='content' cols=50 rows=10></textarea><br />
\t<input type='submit' value='Paste it!' />
</form>
};
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], $main_html], 'route GET /';
    is %data<err>, '';
}, '/';

subtest {
    plan 6;

    my %data1 = run-psgi-request($app, 'POST', '/new_paste', "content=http::/bailador.net");
    my $html = %data1<response>[2];
    %data1<response>[2] = '';
    $html ~~ rx:s/^New paste available at \<a href\=\"paste\/(\d+)\"\>paste\/(\d+)\<\/a\>$/;
    ok $/;
    my $code = $/[1];
    is $/[0], $/[1];
    is-deeply %data1<response>, [200, ["Content-Type" => "text/html"], ''], 'route POST /new_paste';
    is %data1<err>, '';

    my %data2 = run-psgi-request($app, 'GET', "/paste/$code");
    is-deeply %data2<response>, [200, ["Content-Type" => "text/plain"], 'http::/bailador.net'], 'GET /paste/...';
    is %data2<err>, '';


}, 'paste';

rmtree 'data';

