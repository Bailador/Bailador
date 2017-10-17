use v6.c;

use Log::Any;
use Bailador::Route;

class Bailador::Route::StaticFile does Bailador::Route {
    has $.directory is required;

    submethod BUILD(:$!directory, *%_) {
        self.BUILD-ROLE(|%_);
    }

    method execute(Match $path) {
        my $name = $path[0].Str;
        if $name {
            my $file = $.directory.child($name);
            if $file.e && $file.f {
                return $file;
            } else {
                Log::Any.notice("StaticFile route could not find requested file $file");
            }
        }
        return False;
    }

    method build-regex() {
        my $regex = self!get-regex-str();
        $regex = q{/ ^} ~ $regex ~ q{ $ /};
        return $regex.EVAL;
    }
}
