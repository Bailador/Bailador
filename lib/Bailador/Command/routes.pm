use v6;

use Bailador::Command;

class Bailador::Command::routes does Bailador::Command {
    method run(:$app) {
        for $app.routes -> $r {
            put join " ", $r.method.fmt("%10s"), $r.path-str // $r.^name;
        }
    }
}
