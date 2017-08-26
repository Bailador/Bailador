use v6.c;

use HTTP::Easy::PSGI;

use Bailador::Command;
use Bailador::Utils;

class Bailador::Command::easy does Bailador::Command {
    method run(:$app) {
        my $config  = $app.config;
        my $p6w-app = $app.get-psgi-app();
        my $host    = $config.host;
        my $port    = $config.port;
        my $msg     = "Entering the dance floor{ $config.mode eq 'development' ?? ' in development mode' !! ''}: http://$host:$port";

        given HTTP::Easy::PSGI.new(:host($host),:port($port), :silent(True)) {
            .app($p6w-app);
            terminal-color($msg, 'green', $config);
            .run;
        }
    }
}
