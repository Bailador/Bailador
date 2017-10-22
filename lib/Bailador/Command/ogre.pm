use v6.c;

use HTTP::Server::Ogre;

use Bailador::Command;
use Bailador::Utils;

class Bailador::Command::ogre does Bailador::Command {
    method run(:$app) {
        my $config     = $app.config;
        my $p6w-app    = $app.get-psgi-app();
        my $host       = $config.host;
        my $port       = $config.port;
        my $tls-mode   = $config.tls-mode;
        my %tls-config = $config.tls-config;
        my $http-mode  = <1.1>;

        my $protocol   = $tls-mode ?? 'https' !! 'http';
        my $mode       = $config.mode eq 'development' ?? ' in development mode' !! '';
        my $msg        = "Entering the dance floor{ $mode }: { $protocol }://$host:$port";

        given HTTP::Server::Ogre.new(
            :$host,
            :$port,
            :app($p6w-app),
            :http-mode(<1.1>),
            :%tls-config,
            :$tls-mode
        ) {
            terminal-color($msg, 'green', $config);
            .run;
        }
    }
}
