use v6;

use Bailador::Command;
use HTTP::Server::Ogre;

class Bailador::Command::ogre does Bailador::Command {
    method run(:$app) {
        my $config  = $app.config;
        my $p6w-app = $app.get-psgi-app();
        my $host    = $config.host;
        my $port    = $config.port;
        my $msg     = "Entering the dance floor{ $config.mode eq 'development' ?? ' in development mode' !! ''}: http://$host:$port";

        given HTTP::Server::Ogre.new(:$host, :$port, :app($p6w-app)) {
            say $msg;
            .run;
        }
    }
}
