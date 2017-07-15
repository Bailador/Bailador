use v6.c;

use Test;

use Bailador::App;
use Bailador::RouteHelper;
use Bailador::Test;

plan 10;

class MyOwnWebApp is Bailador::App {

    submethod BUILD(|) {
        # config
        self.config.cookie-expiration = 5;

        # routes
        self.add_route: make-simple-route('POST',  '/login/:user' => sub {
            my $user = @_[0];
            my $session = self.session;
            $session<user> = $user;
            self.render: "logged in";
        });
        my $route = make-prefix-route('/app', sub {
            my $session = self.session;
            # go deeper into the nested routes
            return True if self.session<user>;

            # go to a next route that matches the request
            return False;
        });
        $route.add_route: make-simple-route('GET','/something' => self.curry: 'something');
        $route.add_route: make-simple-route('GET','/logout' => sub {
            self.session-delete;
            self.render: "logged out";
        });;
        self.add_route: $route;

        # catch all route
        self.add_route: make-simple-route('GET',/.*/ => sub {
            self.session-delete;
            self.render: "this is the login page / catch all route";
        });
    }

    method something {
        self.render: status => 200, content => "no need to check if we're logged in", type => 'text/plain';
    }
}

my $app = MyOwnWebApp.new.baile('p6w');
my $response;

# not logged in
$response = get-psgi-response($app, 'GET', '/app/something');
is-deeply $response, [200, [:Content-Type("text/html")], "this is the login page / catch all route"], "catch all route because we're not logged in";

$response = get-psgi-response($app, 'POST', '/login/ufobat');
is $response[0], 200, "login successful - statuscode 200";
is $response[2], "logged in", "loggin successful - content";

is $response[1][1].key, "Set-Cookie", "session cookie";
my ($session-cookie-name, $value) = $response[1][1].value.trim.split(/\s*\=\s*/, 2);
my $session-id = $value.split(/<[;&]>/)[0];

$response = get-psgi-response($app, 'GET', '/app/something', headers => { cookie => "$session-cookie-name=$session-id" });
is $response[0], 200, "login successful - statuscode 200";
is $response[1][0].key, "Content-Type", "Content-Type found";
is $response[1][0].value, "text/plain", "Content-Type is text/plain";
is $response[2], "no need to check if we're logged in", "access to the app without checking session in the route";

$response = get-psgi-response($app, 'GET', '/app/logout', headers => { cookie => "$session-cookie-name=$session-id" });
is-deeply $response, [200, [:Content-Type("text/html")], "logged out"] , "logged out";

# get the login page again, because we're not logged in -> catch all again
$response = get-psgi-response($app, 'GET', '/app/logout', headers => { cookie => "$session-cookie-name=$session-id" });
is-deeply $response, [200, [:Content-Type("text/html")], "this is the login page / catch all route"], "logout 2nd time - catchall";
