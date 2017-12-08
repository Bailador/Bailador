use v6.c;

use File::Find;

use Bailador::CLI;
use Bailador::Command;


class Bailador::Command::watch does Bailador::Command {
    has $!process;

    method run(:$app) {
        my $config        = $app.config;
        my $watch-command = $config.watch-command;
        unless $watch-command {
            if $.config.command-detection() {
                my $watch-command = $.commands.detect-command();
            }
        }
        unless $watch-command {
            die 'cannot detect watch-command'
        }

        my $param = %*ENV<BAILADOR>;
        $param ~= ',default-command:' ~ $watch-command;
        %*ENV<BAILADOR> = $param;


        my @watchlist = $config.watch-list;
        die 'nothing to watch, empty watch-list' unless @watchlist;
        $!process = bootup-app();
        signal(SIGINT).tap: { self.kill-process(); exit }
        react {
            whenever watch-recursive(@watchlist.grep: *.IO.e) -> $e {
                if $e.path() !~~ /\.sw.$/ and $e.path() !~~ /\~$/ {
                    say "Change detected [$e.path(), $e.event()]. Restarting app";
                    self.kill-process();
                    $!process = bootup-app();
                }
            }
        }
    }

    method kill-process() {
        $!process.kill(SIGINT);
    }

    my sub bootup-app() {
        my @includes = repo-to-includes();
        my Proc::Async $p .= new($*EXECUTABLE.Str, |@includes, $*PROGRAM.Str);
        $p.stdout.tap: -> $v { $*OUT.print: "# $v" };
        $p.stderr.tap: -> $v { $*ERR.print: "! $v" };
        $p.start;
        return $p;
    }

    my sub watch-recursive(@elements) is export {
        supply {
            for @elements -> $path {
                if $path.IO.d {
                    watch-it($_) for find-dirs $path;
                } else {
                    watch-it($path);
                }
            }
        }
    }

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

    my sub find-dirs (Str:D $p) {
        state $seen = {};
        return slip ($p.IO, slip find :dir($p), :type<dir>).grep: { !$seen{$_}++ };
    }
}
