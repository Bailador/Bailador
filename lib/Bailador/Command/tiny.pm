use v6;

use Bailador::Command;

class Bailador::Command::tiny does Bailador::Command {
    method run(:$app) {
        require HTTP::Server::Tiny;
        my $config  = $app.config;
        my $p6w-app = $app.get-psgi-app();
        my $host    = $config.host;
        my $port    = $config.port;
        my $msg     = "Entering the dance floor{ $config.mode eq 'development' ?? ' in development mode' !! ''}: http://$host:$port";

        given HTTP::Server::Tiny.new(:$host, :$port) {
            say $msg;
            .run($p6w-app);
        }
    }
}
