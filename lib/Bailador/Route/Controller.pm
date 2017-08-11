use v6.c;

use Bailador::Route;

class Bailador::Route::Controller does Bailador::Route {
    has Str $.to is required;
    has $.controller;
    has $.class;

    submethod BUILD(:$!to, :$!class, :$!controller, *%_) {
        self.BUILD-ROLE(|%_);
    }

    method execute(Match $match) {
        my $controller = $.controller // ::($.class).new();
        $controller."$.to"(| $match.list)
    }

    method build-regex() {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ $ /};
        return $regex.EVAL;
    }
}
