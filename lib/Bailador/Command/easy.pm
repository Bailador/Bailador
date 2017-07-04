use v6.c;

use HTTP::Easy::PSGI;

use Bailador::Command;

class Bailador::Command::easy does Bailador::Command {
    method run(:$app) {
        my $config  = $app.config;
        my $p6w-app = $app.get-psgi-app();
        my $host    = $config.host;
        my $port    = $config.port;
        my $msg     = "Entering the dance floor{ $config.mode eq 'development' ?? ' in development mode' !! ''}: http://$host:$port";

        given HTTP::Easy::PSGI.new(:host($host),:port($port)) {
            .app($p6w-app);
            say $msg;
            .run;
        }
    }
}
