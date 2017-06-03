use v6.c;
use File::Find;

unit module Bailador::CLI;

sub usage(Str $msg?) is export {
    if $msg {
        say $msg;
        say '';
    }
    say "Usage:";
    say "    $*PROGRAM-NAME --help               (shows this help)";
    say "    $*PROGRAM-NAME --new Project-Name   (creates a directory called Project-Name with a skeleton application)";
    exit();
}

sub skeleton() is export {
    my %skeleton;
%skeleton{'app.pl'} =
q{use v6;
use Bailador;
Bailador::import();

my $version = '0.01';

get '/' => sub {
    template 'index.tt', { version => $version }
}

app.to-psgi-app();
};


%skeleton{'views/index.tt'} =
q{
% my ($h) = @_;
<!DOCTYPE html>
<html>
  <head>
    <title>Bailador App</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/handlebars.js/3.0.3/handlebars.min.js"></script>
    <script src="http://code.jquery.com/jquery-1.11.3.min.js"></script>
  </head>
  <body>
    <h1>Bailador App</h1>
    <div>
      Version <%= $h<version> %>
    </div>
  </body>
</html>
};

    return %skeleton;
}

my sub bootup-app ($app) is export {
    my $msg     = "Entering the dance floor in reload mode: http://0.0.0.0:3000";
    my $command = "use Bailador; start-p6w-app(3000, '0.0.0.0', EVALFILE('$app'), '$msg')";
    my Proc::Async $p .= new('perl6', "-Ilib", "-e", $command);
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

