use v6;

use Bailador::Command;

class Bailador::Command::routes does Bailador::Command {
    method run(:$app) {
        for $app.routes -> $r {
            my $path = $r.path-str // do { $r.^methods(:local).grep(*.name eq 'Str') && $r.Str } // $r.^name;
            put join " ", $r.method.fmt("%10s"), $path;
        }
    }
}
