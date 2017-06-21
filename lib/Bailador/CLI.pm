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
%skeleton{'bin/app.pl6'} =
q{use v6;
use Bailador;
Bailador::import();

my $version = '0.0.1';

get '/' => sub {
    template 'index.tt', { version => $version }
}

baile();
};

%skeleton{'t/app.t'} =
q{use v6;
use Test;
use Bailador::Test;

plan 1;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
my $app = EVALFILE "bin/app.pl6";

subtest {
    plan 4;
    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    like $html, rx:s/\<h1\>Bailador App\<\/h1\>/;
    like $html, rx:s/Version 0\.01/;
}, '/';
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

my multi sub bootup-file ('easy' ,Str $app, Str $config?) is export {
    my $param = ($config.defined ?? $config !! %*ENV<BAILADOR>);
    $param    ~= ',default-command:easy';
    %*ENV<BAILADOR> = $param;
    bootup-file($app);
}

my multi sub bootup-file ('watch', Str $app, Str $w, Str $config?) is export {

    my @watchlist = $w.split: /<!after \\> \,/;
    s/\\\,/,/ for @watchlist;

    my $param = ($config.defined ?? $config !! %*ENV<BAILADOR>);

    $param ~= ',default-command:watch,watch-command:easy';
    for @watchlist -> $w {
        $param ~= ",watch-list:" ~ $w;
    }
    %*ENV<BAILADOR> = $param;
    bootup-file($app);
}

multi sub bootup-file (Str $app) {
    say "Attempting to boot up the app";
    my @includes = repo-to-includes();
    my Proc::Async $p .= new($*EXECUTABLE, |@includes, $app);
    $p.stdout.tap: -> $v { $*OUT.print: "# $v" };
    $p.stderr.tap: -> $v { $*ERR.print: "! $v" };
    await $p.start;
}

sub repo-to-includes is export {
    my @includes;
    for $*REPO.repo-chain -> $repo {
        if $repo ~~ CompUnit::Repository::FileSystem {
            @includes.push: '-I' ~ $repo.prefix;
        }
    }
    return @includes;
}

