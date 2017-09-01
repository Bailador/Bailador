use v6.c;
use Bailador::Route;

class Bailador::Route::IoC does Bailador::Route {
    has Str $.to is required;
    has $.container is required;
    has $.service is required;

    submethod BUILD(:$!to, :$!service, :$!container, *%_) {
        self.BUILD-ROLE(|%_);
    }

    method execute(Match $match) {
        my $controller = $.container.resolve($.service);
        $controller."$.to"(| $match.list)
    }

    method build-regex() {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ $ /};
        return $regex.EVAL;
    }
}
