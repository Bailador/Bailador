use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 8;

my $not-found-template will leave { .unlink } = $?FILE.IO.parent.child('views').child('404.xx');
my $error-template will leave { .unlink }     = $?FILE.IO.parent.child('views').child('500.xx');
my $resp;

get '/die' => sub { die 'something' };


# 404
ok not $not-found-template.e , 'there is no 404 template';

$resp = get-psgi-response('GET',  '/notexisting');
is-deeply $resp,[404, ["Content-Type" => "text/html, charset=utf-8"], 'Not found' ], '404 - without error template';

$not-found-template.spurt: 'nada';
ok $not-found-template.e , 'there is a 404 template';

$resp = get-psgi-response('GET',  '/notexisting');
is-deeply $resp, [404, ["Content-Type" => "text/html, charset=utf-8"], 'nada' ], '404 - with error template';

# 500
ok not $error-template.e, 'there is no 500 template';

$resp = get-psgi-response('GET', '/die');

is-deeply $resp, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error' ], '500 - without error template';

$error-template.spurt: 'muerte';
ok $error-template.e, 'there is a 500 template';

$resp = get-psgi-response('GET', '/die');
is-deeply $resp, [500, ["Content-Type" => "text/html, charset=utf-8"], 'muerte' ], '500 - with error template';
