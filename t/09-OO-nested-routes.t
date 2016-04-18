use Test;
use Bailador::App;
use Bailador::Route;
use Bailador::Test;

plan 8;

class MyOwnWebApp is Bailador::App {

    submethod BUILD(|) {
        # config
        self.sessions-config.cookie-expiration = 5;

        # routes
        self.post: '/login/:user' => sub {
            my $user = @_[0];
            my $session = self.session;
            $session<user> = $user;
            self.render: "logged in";
        }
        my $route = Bailador::Route.new: path => /.*/, code => sub {
            my $session = self.session;

            # go deeper into the nested routes
            return True if self.session<user>;

            # go to a next route that matches the request
            return False;
        };
        $route.get: '/app/something' => sub {
            self.render: "no need to check if we're logged in";
        };
        $route.get: '/logout' => sub {
            self.session-delete;
            self.render: "logged out";
        };
        self.add_route: $route;

        # catch all route
        self.get: /.*/ => sub {
            self.session-delete;
            self.render: "this is the login page / catch all route";
        };
    }
}

my $app = MyOwnWebApp.new;
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

$response = get-psgi-response($app, 'GET', '/app/something', http_cookie => "$session-cookie-name=$session-id");
is $response[0], 200, "login successful - statuscode 200";
is $response[2], "no need to check if we're logged in", "access to the app without checking session in the route";

$response = get-psgi-response($app, 'GET', '/logout', http_cookie => "$session-cookie-name=$session-id");
is-deeply $response, [200, [:Content-Type("text/html")], "logged out"] , "logged out";

# get the login page again, because we're not logged in -> catch all again
$response = get-psgi-response($app, 'GET', '/logout', http_cookie => "$session-cookie-name=$session-id");
is-deeply $response, [200, [:Content-Type("text/html")], "this is the login page / catch all route"], "logout 2nd time - catchall";

