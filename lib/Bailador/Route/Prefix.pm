use v6.c;

use Bailador::Route;

class Bailador::Route::Prefix does Bailador::Route {
    has $.prefix-enter-code is rw;
    # a prefix route can have an optional code block

    submethod BUILD(:$!prefix-enter-code?, *%_) {
        self.BUILD-ROLE(|%_);
    }
    method execute(Match $match) {
        return $.prefix-enter-code.(| $match.list) if $.prefix-enter-code;
        return True;
    }

    method build-regex {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ [ $ || <?before '/' > ] /};
        return $regex.EVAL;
    }

    method set-prefix-enter(Callable $code) {
        $.prefix-enter-code = $code;
    }
}
