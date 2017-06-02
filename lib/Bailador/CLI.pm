use v6.c;
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

baile;
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

