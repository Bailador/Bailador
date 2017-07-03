use v6.c;
use lib 'lib';

use Path::Iterator;
use Test;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if AUTHOR {
    # check for trailing spaces
    # check for tabs
    my @dirs = '.';
    for Path::Iterator.skip-vcs.ext(rx/ ^ ( 'p' <[lm]> 6? | t ) $ /).in(@dirs) -> $file {
        check_tidy($file);
    }
    for Path::Iterator.skip-vcs.in('examples') -> $file {
        next if not $file.f;
        check_tidy($file);
    }
    check_tidy('bin/bailador');
    check_tidy('README.md');
    done-testing;
}
else {
     plan 1;
     skip-rest "Skipping author test";
     diag "Skipping author test. Set AUTHOR_TESTING to enable.";
     exit;
}

sub check_tidy($file) {
    #diag $file;
    my @lines = $file.IO.lines;
    my @spaces = @lines.grep(rx/\s$/);
    is-deeply @spaces, [], "spaces at the end of $file";

    my @tabs = @lines.grep(rx/\t/);
    is-deeply @tabs, [], "tabs in $file";
}

