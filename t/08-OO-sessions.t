use v6.c;

use Test;

use Bailador::App;
use Bailador::RouteHelper;
use Bailador::Test;

plan 5;

class MyOwnWebApp is Bailador::App {
    submethod BUILD (|) {
        self.config.cookie-expiration = 5;
        self.add_route: make-simple-route('GET','/setsession' => sub {
            my $session = self.session;
            $session<key> = 'value';
            "with session";
        });

        self.add_route: make-simple-route('GET','/readsession' => sub {
            my $session = self.session;
            $session<key> || 'no value';
        });

        self.add_route: make-simple-route('GET','/deletesession' => sub {
            self.session-delete;
            "session should be deleted";
        });
    }
}

my $app = MyOwnWebApp.new().baile('p6w');
my $first-session-id;
my $wrong-session-id;
my $second-session-id;

my $session-cookie-name;

subtest {
    plan 3;

    my %data = run-psgi-request($app, 'GET', '/setsession');
    my $response = %data<response>;
    is $response[0], 200, 'New session HTTP status 200';

    my %header = $response[1];
    ok %header<Set-Cookie>:exists, 'Session cookie available';
    my $cookie = %header<Set-Cookie>;
    my $value;
    ($session-cookie-name, $value) = $cookie.trim.split(/\s*\=\s*/, 2);
    $first-session-id = $value.split(/<[;&]>/)[0];
    is($response[2], 'with session', 'New session Content');

}, 'Set inital session';

subtest {
    plan 3;
    my %data = run-psgi-request($app, 'GET', '/readsession', headers => { cookie => "$session-cookie-name=$first-session-id" });
    my $response = %data<response>;
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

    my %data = run-psgi-request($app, 'GET', '/readsession', headers => { cookie => "$session-cookie-name=$wrong-session-id" });
    my $response = %data<response>;
    is $response[0], 200, 'With session HTTP status 200';
    my %header = $response[1];

    ok %header<Set-Cookie>:exists, 'Session cookie available';
    is($response[2], 'no value', 'No data from last session available');

}, 'Fake session ID';

subtest {
    plan 4;
    # let the cookie expire!
    sleep 6;

    my %data = run-psgi-request($app, 'GET', '/readsession', headers => { cookie => "$session-cookie-name=$first-session-id" });
    my $response = %data<response>;
    is $response[0], 200, 'With session HTTP status 200';
    my %header = $response[1];

    ok %header<Set-Cookie>:exists, 'Session cookie available';
    is $response[2], 'no value', 'Data from last session is timed out';

    my $cookie = %header<Set-Cookie>;
    my $value;
    ($session-cookie-name, $value) = $cookie.trim.split(/\s*\=\s*/, 2);
    $second-session-id = $value.split(/<[;&]>/)[0];

    isnt $first-session-id, $second-session-id, 'got a new session ID because old session was timed out';

}, 'Session expiration';

subtest {
    plan 1;
    my %data = run-psgi-request($app, 'GET', '/deletesession', headers => { cookie => "$session-cookie-name=$second-session-id" });
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], 'session should be deleted'], 'Session deletion';
}, 'Session deletion';

done-testing;
