use v6.c;

use Bailador::Command;

class Bailador::Command::p6w does Bailador::Command {
    method run(:$app) {
        return $app.get-psgi-app();
    }
}
