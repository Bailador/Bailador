use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 1;

get '/' => sub {
    return "key='{request.headers<X_CORP_API_KEY>}' secret='{request.headers<X_CORP_API_SECRET>}'";
}

# Call baile just once
my $p6w-app = baile('p6w');

subtest {
    plan 1;
    my %data = run-psgi-request($p6w-app, 'GET', '/', headers => {  X_CORP_API_KEY => 'private-api-key', X_CORP_API_SECRET => '42' });
    my $response = %data<response>;
    is-deeply $response, [ 200, ["Content-Type" => "text/html;charset=UTF-8"], "key='private-api-key' secret='42'" ], 'header set';
};
