use v6;
use File::Temp;

use lib 'lib';
use Test;

plan 7;

my $dir = tempdir();
#diag $dir;

my $git_dir = $*CWD;
chdir($dir);
#diag $*CWD;

{
    my $p = run $*EXECUTABLE, $git_dir.IO.child('bin').child('bailador'), :out, :err;
    is $p.out.get, 'Usage:';
    is $p.err.get, Nil;
    #diag $p.out.slurp: :close;
}


{
    my $p = run $*EXECUTABLE, $git_dir.IO.child('bin').child('bailador'), 'App-Name', :out, :err;
    my $out = $p.out.slurp: :close;
    is $out, q{Generating App-Name
views/index.tt
app.pl
};
    my $err = $p.err.slurp: :close;
    is $err, ''; # TODO Why is this the empty string and above it is Nil?
    my @main_dir = dir();
    is-deeply @main_dir.map(*.Str), ('App-Name',);

    my @app_dir = dir('App-Name');
    is-deeply @app_dir.map(*.Str), ('App-Name/app.pl', 'App-Name/views');

    my @views_dir = dir('App-Name/views');
    is-deeply @views_dir.map(*.Str), ('App-Name/views/index.tt',);
}

# vim: expandtab
# vim: tabstop=4
