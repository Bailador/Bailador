use v6;

use Bailador::Command;

class Bailador::Command::routes does Bailador::Command {
    method run(:$app) {
        for $app.routes -> $r {
            say "$r.method.fmt("%10s")  {$r.path-str}";
        }
    }
}
