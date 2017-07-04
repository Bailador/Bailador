use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 6;

get '/die' => sub { die "oh no!" }
get '/fail' => sub { fail "hell froze!" }
get '/exception' => sub { X::NYI.new(feature => 'NYI').throw }

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/die');
    is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles die';
    like %data<err>, rx:s/oh no\!/, 'stderr';
};

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/fail');
    is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles fail';
    like %data<err>, rx:s/hell froze\!/, 'stderr';
};

subtest {
    plan 2;
    my %data = run-psgi-request('GET', '/exception');
    is-deeply %data<response>, [500, ["Content-Type" => "text/plain;charset=UTF-8"], 'Internal Server Error'], 'route GET handles thrown exception';
    like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
};

subtest {
    plan 3;
    config.mode = 'development';
    my %data = run-psgi-request('GET', '/die');
    my $html = %data<response>[2];
    like $html, rx:s/In the future this will be a nice error page\. For now we try to make it at least informative\./;
    %data<response>[2] = '';
    is-deeply %data<response>, [500, ["Content-Type" => "text/html;charset=UTF-8"], ''], 'route GET handles die';
    like %data<err>, rx:s/oh no\!/, 'stderr';
}

subtest {
    plan 3;
    config.mode = 'development';
    my %data = run-psgi-request('GET', '/fail');
    my $html = %data<response>[2];
    like $html, rx:s/In the future this will be a nice error page\. For now we try to make it at least informative\./;
    %data<response>[2] = '';
    is-deeply %data<response>, [500, ["Content-Type" => "text/html;charset=UTF-8"], ''], 'route GET handles die';
    like %data<err>, rx:s/hell froze\!/, 'stderr';
}

subtest {
    plan 3;
    config.mode = 'development';
    my %data = run-psgi-request('GET', '/exception');
    my $html = %data<response>[2];
    like $html, rx:s/In the future this will be a nice error page\. For now we try to make it at least informative\./;
    %data<response>[2] = '';
    is-deeply %data<response>, [500, ["Content-Type" => "text/html;charset=UTF-8"], ''], 'route GET handles die';
    like %data<err>, rx:s/NYI not yet implemented\. Sorry\./, 'stderr';
}


# vim: expandtab
# vim: tabstop=4
