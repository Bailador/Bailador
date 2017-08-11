use v6.c;

use Bailador::RouteHelper;
class SharedApp is Bailador::App {
    submethod BUILD(|) {
        self.add_route: make-route('GET', '/' => sub {
            q{<h1>Welcome to root of the Shared App</h1>}
        });
        self.add_route: make-route('GET', '/sharedapp' => sub {
            q{Route /sharedapp of Shared App};
        });
    }
}

