use v6.c;

use Bailador::RouteHelper;
class MyWebApp is Bailador::App {
    submethod BUILD(|) {
        self.add_route: make-simple-route('GET','/' => sub {
            q{
                <h1>Welcome to Bailador!</h1>
                <ul>
                  <li><a href="/param/abc">/param/abc</a></li>
                </ul>
            }
        });
        self.add_route: make-simple-route('GET','/param/:code' => sub ($code) {
            return "Code: $code";
        });

        self.add_route: make-simple-route('GET','/params/:a/:b' => sub ($x, $y) {
            return "Params: '$x' '$y'";
        });
        self.add_route: make-simple-route('GET','/from' => sub {self.redirect: '/to' });
        self.add_route: make-simple-route('GET','/to' => sub { 'Arrived to.' });

        self.add_route: make-simple-route('GET', / ^ '/tmpl/' (.+) $ / => sub ($x) {
            self.template('tmpl.tt', { name => $x });
        });
    }
}
my $app = MyWebApp.new.baile();

