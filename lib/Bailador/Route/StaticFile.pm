use v6.c;

use Bailador::Route;

class Bailador::Route::StaticFile is Bailador::Route {
    has $.directory is required;

    method new(*%attr) {
        my $obj = self.bless: method => 'GET', code => sub {}, |%attr;
        $obj.code = $obj.^find_method('check-for-file').assuming($obj);
        return $obj;
    }

    method check-for-file(Match $path) {
        my $file = $.directory.child($path.Str);
        return $file if $file.f;
        return False;
    }

    method Str() {
        "{self.^name} $.directory"
    }
}
