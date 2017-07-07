use v6.c;

use Bailador::Route;

class Bailador::Route::Simple does Bailador::Route {
    has Callable $.code is required;

    submethod BUILD(:$!code, *%_) {
        self.BUILD-ROLE(|%_);
    }

    method execute(Match $match) {
        $.code.(| $match.list);
    }

    method build-regex() {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ $ /};
        return $regex.EVAL;
    }
}
