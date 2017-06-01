use v6;
use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 12;

my $not-found-template will leave { .unlink } = $?FILE.IO.parent.child('views').child('404.xx');
my $error-template will leave { .unlink }     = $?FILE.IO.parent.child('views').child('500.xx');
my %resp;

get '/die' => sub { die 'something' };


# 404
ok not $not-found-template.e , 'there is no 404 template';

%resp = run-psgi-request('GET',  '/notexisting');
is-deeply %resp<response>, [404, ["Content-Type" => "text/html, charset=utf-8"], 'Not found' ], '404 - without error template';
is %resp<err>, '', 'no stderr';

$not-found-template.spurt: 'nada';
ok $not-found-template.e , 'there is a 404 template';

%resp = run-psgi-request('GET',  '/notexisting');
is-deeply %resp<response>, [404, ["Content-Type" => "text/html, charset=utf-8"], 'nada' ], '404 - with error template';
is %resp<err>, '', 'no stderr';
#like %resp<err>, rx:s//, 'stderr';

# 500
ok not $error-template.e, 'there is no 500 template';

%resp = run-psgi-request('GET', '/die');

is-deeply %resp<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'Internal Server Error' ], '500 - without error template';
like %resp<err>, rx:s/something/, 'stderr';

$error-template.spurt: 'muerte';
ok $error-template.e, 'there is a 500 template';

%resp = run-psgi-request('GET', '/die');
is-deeply %resp<response>, [500, ["Content-Type" => "text/html, charset=utf-8"], 'muerte' ], '500 - with error template';
like %resp<err>, rx:s/something/, 'stderr';
