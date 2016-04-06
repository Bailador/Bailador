use v6;
use Test;
use Bailador;
use Bailador::Test;

sessions-config.cookie-expiration = 5;

plan 5;

get '/setsession' => sub {
    my $session = session;
    $session<key> = 'value';
    "with session";
}

get '/readsession' => sub {
    my $session = session;
    $session<key> || 'no value';
}

get '/deletesession' => sub {
    session-delete;
    "session should be deleted";
}

my $first-session-id;
my $wrong-session-id;
my $second-session-id;

my $session-cookie-name;

subtest {
    plan 3;

    my $response = get-psgi-response('GET', '/setsession');
    is $response[0], 200, 'New session HTTP status 200';

    my %header = $response[1];
    ok %header<Set-Cookie>:exists, 'Session cookie available';
    my $cookie = %header<Set-Cookie>;
    my $value;
    ($session-cookie-name, $value) = $cookie.trim.split(/\s*\=\s*/, 2);
    $first-session-id = $value.split(/<[;&]>/)[0];
    diag "SessionID: $first-session-id";
    is($response[2], 'with session', 'New session Content');

}, 'Set inital session';

subtest {
    plan 3;
    my $response = get-psgi-response('GET', '/readsession', http_cookie => "$session-cookie-name=$first-session-id");
    is $response[0], 200, 'With session HTTP status 200';
    my %header = $response[1];

    ok %header<Set-Cookie>:exists, 'Session cookie available';
    is($response[2], 'value', 'Data from last session available');

}, 'Read session';


subtest {
    plan 3;

    $wrong-session-id = $first-session-id;
    $wrong-session-id.substr-rw(0,1) = '1';
    if $wrong-session-id eq $first-session-id {
        $wrong-session-id.substr-rw(0,1) = '2';
    }

    diag "Sending wrong SessionID: $wrong-session-id";
    my $response = get-psgi-response('GET', '/readsession', http_cookie => "$session-cookie-name=$wrong-session-id");
    is $response[0], 200, 'With session HTTP status 200';
    my %header = $response[1];

    ok %header<Set-Cookie>:exists, 'Session cookie available';
    is($response[2], 'no value', 'No data from last session available');

}, 'Fake session ID';

subtest {
    plan 4;
    # let the cookie expire!
    sleep 6;

    my $response = get-psgi-response('GET', '/readsession', http_cookie => "$session-cookie-name=$first-session-id");
    is $response[0], 200, 'With session HTTP status 200';
    my %header = $response[1];

    ok %header<Set-Cookie>:exists, 'Session cookie available';
    is $response[2], 'no value', 'Data from last session is timed out';

    my $cookie = %header<Set-Cookie>;
    my $value;
    ($session-cookie-name, $value) = $cookie.trim.split(/\s*\=\s*/, 2);
    $second-session-id = $value.split(/<[;&]>/)[0];

    isnt $first-session-id, $second-session-id, 'got a new session ID because old session was timed out';
    diag "SessionID: $second-session-id";

}, 'Session expiration';

subtest {
    plan 1;
    my $response = get-psgi-response('GET', '/deletesession', http_cookie => "$session-cookie-name=$second-session-id");
    is-deeply $response, [200, ["Content-Type" => "text/html"], 'session should be deleted'], 'Session deletion';
}, 'Session deletion';

done-testing;
