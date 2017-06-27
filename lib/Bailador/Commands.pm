use v6;

use Bailador::Command::easy;
use Bailador::Command::ogre;
use Bailador::Command::p6w;
use Bailador::Command::watch;

class Bailador::Commands {
    has @.namespaces = ( 'Bailador::Command' );

    method add-ns(Str:D $namespace) {
        @.namespaces.push: $namespace;
    }

    method get-command(Str:D $command, *@args) {
        my $cmd;
        for @.namespaces -> $ns {
            my $module = $ns ~ '::' ~ $command;
            try {
                require ::($module);
                $cmd = ::($module).new( args => @args);
                last;
            }
        }
        unless $cmd {
            X::NYI.new(feature => $command).throw;
        }
        return $cmd;
    }

    method detect-command() {
        if %*ENV<P6SGI_CONTAINER> || %*ENV<P6W_CONTAINER> {
            'p6w';
        }
        else {
            'easy'
        }
    }
}
