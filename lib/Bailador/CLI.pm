use v6.c;

unit module Bailador::CLI;

sub skeleton() is export {
    my %skeleton;
%skeleton{'bin/app.pl6'} =
q{use v6.c;
use Bailador;

my $version = '0.0.1';

get '/' => sub {
    template 'index.html', { version => $version }
}

baile();
};

%skeleton{'t/app.t'} =
q{use v6.c;
use Test;
use Bailador::Test;

plan 1;

%*ENV<P6W_CONTAINER> = 'Bailador::Test';
%*ENV<BAILADOR_APP_ROOT> = $*CWD.absolute;
my $app = EVALFILE "bin/app.pl6";

subtest {
    plan 4;
    my %data = run-psgi-request($app, 'GET', '/');
    my $html = %data<response>[2];
    %data<response>[2] = '';
    is-deeply %data<response>, [200, ["Content-Type" => "text/html"], ''], 'route GET /';
    is %data<err>, '';
    like $html, rx:s/\<h1\>Bailador App\<\/h1\>/;
    like $html, rx:s/Version 0\.0\.1/;
}, '/';
};

%skeleton{'views/index.html'} =
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

my multi sub bootup-file ('watch', Str $app, Str $w, Str $config?) is export {

    my @watchlist;

    if $w {
        my @list = $w.split: /<!after \\> \,/;
        s/\\\,/,/ for @list;
        @watchlist = @list.grep: *.IO.e;
    }

    @watchlist.unshift: $app;

    my $param = ($config.defined ?? $config !! %*ENV<BAILADOR>);

    $param ~= ',default-command:watch,watch-command:easy';
    for @watchlist -> $w {
        $param ~= ",watch-list:" ~ $w;
    }
    %*ENV<BAILADOR> = $param;
    bootup-file($app);
}

my multi sub bootup-file ('routes', Str $app, Bool $tree, Str $config?) is export {
    my $param = ($config.defined ?? $config !! %*ENV<BAILADOR>);
    $param ~= ',default-command:routes,routes-output:' ~ ($tree ?? 'tree' !! 'plain');
    %*ENV<BAILADOR> = $param;
    bootup-file($app);
}

my multi sub bootup-file (Str $cmd where {$cmd ~~ any <easy tiny ogre>}, Str $app, Str $config?) is export {
    my $param = ($config.defined ?? $config !! %*ENV<BAILADOR>);
    $param ~= ',default-command:' ~ $cmd;
    %*ENV<BAILADOR> = $param;
    bootup-file($app);
}

multi sub bootup-file (Str $app) {
    say "Attempting to boot up the app";
    my @includes = repo-to-includes();
    my Proc::Async $p .= new($*EXECUTABLE, |@includes, $app);
    $p.stdout.tap: -> $v { $*OUT.print: "# $v" };
    $p.stderr.tap: -> $v { $*ERR.print: "! $v" };
    signal(SIGINT).tap: { $p.kill(SIGINT) }
    await $p.start;
}

sub get-path-from-repo is export {
    my @includes;
    for $*REPO.repo-chain -> $repo {
        if $repo ~~ CompUnit::Repository::FileSystem {
            @includes.push: $repo.prefix;
        }
    }
    return @includes;
}

sub repo-to-includes is export {
    get-path-from-repo().map: '-I' ~ *;
}

sub run-executable-with-includes(*@args, *%args) is export {
    my @includes = repo-to-includes();
    return run($*EXECUTABLE, |@includes, |@args, |%args);
}
