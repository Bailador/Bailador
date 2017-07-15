use v6.c;

use Bailador::Route;

class Bailador::Route::StaticFile does Bailador::Route {
    has $.directory is required;

    submethod BUILD(:$!directory, *%_) {
        self.BUILD-ROLE(|%_);
    }

    method execute(Match $path) {
        my $file = $.directory.child($path.Str);
        return $file if $file.e && $file.f;
        return False;
    }

    method build-regex() {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ $ /};
        return $regex.EVAL;
    }
}
