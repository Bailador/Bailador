use v6.c;

unit module Bailador::CLI;

sub write-skeletonfiles(Str $appname, Str $type = 'default') is export {

    my %skeleton;
    # thats not cool :(
    if $type eq 'default' {
        %skeleton<bin><app.pl6>      = %?RESOURCES<skeleton/default/bin/app.pl6>.IO.slurp;
        %skeleton<t><app.t>          = %?RESOURCES<skeleton/default/t/app.t>.IO.slurp;
        %skeleton<views><index.html> = %?RESOURCES<skeleton/default/views/index.html>.IO.slurp;
    } else {
        X::NYI.new(feature => 'skeleton with type ' ~ $type).throw;
    }

    mkdir $appname;
    sub create-files(IO::Path $dir, %data) {
        for %data.kv -> $filename, $data {
            if $data ~~ Hash {
                my $subdir = $dir.add($filename).mkdir;
                create-files($subdir, $data);
            } else {
                my $file = $dir.add($filename);
                $file.spurt($data);
                say $file.Str;
            }
        }

    }
    create-files($appname.IO, %skeleton);
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
