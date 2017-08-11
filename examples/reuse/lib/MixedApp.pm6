use v6.c;
use SharedApp;

use Bailador::RouteHelper;
class MixedApp is Bailador::App {
    submethod BUILD(|) {
        self.add_route: make-route('GET','/' => sub {
            q{<h1>Welcome to the root of MixedApp</h1>}
        });
        self.add_route: make-route('GET','/mixedapp' => sub {
            return 'Route /mixedapp';
        });

        # TODO
        #self.add_prefix('/reuse', => SharedApp)
    }
}

