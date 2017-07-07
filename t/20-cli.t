use v6.c;
use lib 'lib','t/lib';

use File::Temp;
use Helpers;
use Test;

plan 6;

my $dir = tempdir();
#diag $dir;

my $git_dir = $*CWD;
chdir($dir);
#diag $*CWD;

subtest {
    plan 2;

    my $p = run $*EXECUTABLE, "-I$git_dir/lib", $git_dir.IO.child('bin').child('bailador'), :out, :err;
    is $p.err.get, 'Usage:';
    is $p.out.get, Nil;
    #diag $p.out.slurp: :close;
}, 'Show Usage when no parameter is supplied.';

subtest {
    plan 2;

    my $p = run $*EXECUTABLE, "-I$git_dir/lib", $git_dir.IO.child('bin').child('bailador'), 'new', :out, :err;
    is $p.out.get, '--name=Project-Name is a required parameter';
    is $p.err.get, Nil;
    #diag $p.out.slurp: :close;
}, 'Show Usage when --name is not supplied.';



subtest {
    plan 7;

    my $p = run $*EXECUTABLE, "-I$git_dir/lib", $git_dir.IO.child('bin').child('bailador'), '--name=App-Name', 'new', :out, :err;
    my $out = $p.out.slurp: :close;
    is $out, q{Generating App-Name
bin/app.pl6
t/app.t
views/index.html
};
    my $err = $p.err.slurp: :close;
    is $err, ''; # TODO Why is this the empty string and above it is Nil?
    my @main_dir = dir();
    is-deeply @main_dir.map(*.Str), ('App-Name',);

    my @app_dir = dir('App-Name');
    is-deeply @app_dir.map(*.Str).sort, ('App-Name/bin', 'App-Name/t', 'App-Name/views');

    my @views_dir = dir('App-Name/views');
    is-deeply @views_dir.map(*.Str), ('App-Name/views/index.html',);

    my @bin_dir = dir('App-Name/bin/');
    is-deeply @bin_dir.map(*.Str), ('App-Name/bin/app.pl6',);

    my @t_dir = dir('App-Name/t');
    is-deeply @t_dir.map(*.Str), ('App-Name/t/app.t',);
}, 'Create application';

subtest {
    plan 2;

    my $p = run $*EXECUTABLE, "-I$git_dir/lib", $git_dir.IO.child('bin').child('bailador'), '--name=App-Name', 'new', :out, :err;
    my $out = $p.out.slurp: :close;
    is $out, q{Generating App-Name
App-Name already exists. Exiting.
};
    my $err = $p.err.slurp: :close;
    is $err, ''; # TODO Why is this the empty string and above it is Nil?
}, 'Will not overwrite existing directory';

subtest {
    plan 2;

    chdir 'App-Name';
    temp %*ENV<PERL6LIB> = "$git_dir/lib";
    my $p = run 'prove6', '-l', :out, :err;
    my $out = $p.out.slurp: :close;
    like $out, rx:s/Result\: PASS/;
    my $err = $p.err.slurp: :close;
    is $err, '';
    chdir '..';
}

subtest {
    plan 1;
    my $port = 5005;
    my @args = "--config=host:0.0.0.0,port:$port", "-w={$git_dir.IO.child('t').child('views')}", 'watch',
               $git_dir.IO.child('t').child('apps').child('app.pl6');
    my $server = start { run $*EXECUTABLE, "-I$git_dir/lib", $git_dir.IO.child('bin').child('bailador'), @args, :out, :err  }

    # Wait for server to come online
    wait-port($port, times => 600);

    my $expected = "host:0.0.0.0,port:$port";
        ok req("GET /config HTTP/1.0\r\nContent-length: 0\r\n\r\n", $port) ~~ / $expected /;
}, '--config options are stored in BAILADOR env';

# vim: expandtab
# vim: tabstop=4
