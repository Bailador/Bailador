use v6.c;
use SharedApp;

use Bailador::RouteHelper;
class InheritApp is SharedApp {
    submethod BUILD(|) {
# Currently (in 0.0.10) cannot override route from parent app
#        self.add_route: make-simple-route('GET','/' => sub {
#            q{
#                <h1>Welcome to InheritApp</h1>
#            }
#        });
        self.add_route: make-simple-route('GET','/inheritapp' => sub {
            return 'Route /inheritapp';
        });
    }
}
