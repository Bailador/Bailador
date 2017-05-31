use v6;
use Test;
use Bailador;
use Bailador::Test;

plan 4;

get '/die' => sub { die "oh no!" }
get '/fail' => sub { fail "oh no!" }
get '/exception' => sub { X::NYI.new(feature => 'NYI').throw }

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/die');
    is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles die';
    like %data<err>, rx:s/oh no\!/, 'stderr';
};

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/fail');
    is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles fail';
    like %data<err>, rx:s/oh no\!/, 'stderr';
};

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/exception');
    is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error'], 'route GET handles thrown exception';
    like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
};

subtest {
    plan 3;
    config.mode = 'development';
    my %data = run-psgi-request('GET', '/die');
    my $html = %data<response>[2];
    like $html, rx:s/In the future this will be a nice error page\. For now we try to make it at least informative\./;
    %data<response>[2] = '';
    is-deeply %data<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], ''], 'route GET handles die';
    like %data<err>, rx:s/oh no\!/, 'stderr';
}

# vim: expandtab
# vim: tabstop=4

