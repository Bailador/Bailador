use v6;

use Bailador::Command;
use File::Find;

class Bailador::Command::watch does Bailador::Command {
    method run(:$app) {
        my $config        = $app.config;
        my $watch-command = $config.watch-command;
        unless $watch-command {
            if $.config.command-detection() {
                my $watch-command = $.commands.detect-command();
            }
        }
        unless $watch-command {
            die 'can not detect watch-command'
        }

        my $param = %*ENV<BAILADOR>;
        $param ~= ',default-command:' ~ $watch-command;
        say $param;
        %*ENV<BAILADOR> = $param;


        my @watchlist = $config.watch-list;
        die 'nothing to watch, empty watch-list' unless @watchlist;
        say @watchlist;
        my $p         = bootup-app();
        say $p;
        react {
            whenever watch-recursive(@watchlist.grep: *.IO.e) -> $e {
                if $e.path() !~~ /\.sw.$/ and $e.path() !~~ /\~$/ {
                    say "Change detected [$e.path(), $e.event()]. Restarting app";
                    $p.kill;
                    $p = bootup-app();
                }
            }
        }
        say "react done";
    }

    my sub bootup-app() {
        # TODO take care about $*REPO
        say $*EXECUTABLE;
        say $*PROGRAM;
        my Proc::Async $p .= new($*EXECUTABLE.Str, "-Ilib", $*PROGRAM.Str);
        $p.stdout.tap: -> $v { $*OUT.print: "# $v" };
        $p.stderr.tap: -> $v { $*ERR.print: "! $v" };
        $p.start;
        return $p;
    }

    my sub watch-recursive(@dirs) is export {
        supply {
            my sub watch-it($p) {
                if ( $p ~~ rx{ '/'? '.precomp' [ '/' | $ ] } ) {
                    #say "Skipping .precomp dir [$p]";
                    return;
                }
                say "Starting watch on `$p`";
                whenever IO::Notification.watch-path($p) -> $e {
                    if $e.event ~~ FileRenamed && $e.path.IO ~~ :d {
                        watch-it($_) for find-dirs $e.path;
                    }
                    emit($e);
                }
            }
            watch-it(~$_) for |@dirs.map: { find-dirs $_ };
        }
    }

    my sub find-dirs (Str:D $p) {
        state $seen = {};
        return slip ($p.IO, slip find :dir($p), :type<dir>).grep: { !$seen{$_}++ };
    }
}


