use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 10;

use-feature('AutoHead');

get '/123' => sub { '/123' };

prefix '/abc' => sub {

    get  '/x' => sub { '/abc/x' };
    head '/x' => sub {
        # text/plain to prove its not a AutoHead HEAD route
        app.render: :type('text/plain'), :content('')
    };

    get  '/y' => sub { '/abc/y' };

    prefix '/def' => sub {
        get '/g' => sub { '/abc/def/g' };
    }
};

is-deeply get-psgi-response('GET',  '/123'),       [200, ["Content-Type" => "text/html"], '/123'],                     'route GET /abc/x';
is-deeply get-psgi-response('GET',  '/abc'),       [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /abc';
is-deeply get-psgi-response('GET',  '/abc/x'),     [200, ["Content-Type" => "text/html"], '/abc/x'],                   'route GET /abc/x';
is-deeply get-psgi-response('GET',  '/abc/y'),     [200, ["Content-Type" => "text/html"], '/abc/y'],                   'route GET /abc/y';
is-deeply get-psgi-response('GET',  '/abc/def'),   [404, ["Content-Type" => "text/plain;charset=UTF-8"], 'Not found'], 'route GET /abc/def';
is-deeply get-psgi-response('GET',  '/abc/def/g'), [200, ["Content-Type" => "text/html"], '/abc/def/g'],               'route GET /abc/def/g';

# explicit HEAD
is-deeply get-psgi-response('HEAD', '/abc/x'),     [200, ["Content-Type" => "text/plain"], ''],                        'route HEAD /abc/x';

# autohead
is-deeply get-psgi-response('HEAD',  '/123'),      [200, ["Content-Type" => "text/html"], ''],                         'route HEAD /123';

# autohead in prefix
is-deeply get-psgi-response('HEAD', '/abc/y'),     [200, ["Content-Type" => "text/html"], ''],                         'route HEAD /abc/y';
is-deeply get-psgi-response('HEAD', '/abc/y'),     [200, ["Content-Type" => "text/html"], ''],                         'route HEAD /abc/y';

done-testing;
