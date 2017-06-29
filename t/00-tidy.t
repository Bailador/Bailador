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
        my @lines = $file.IO.lines;
        my @spaces = @lines.grep(rx/\s$/);
        is-deeply @spaces, [], "spaces at the end of $file";

        my @tabs = @lines.grep(rx/\t/);
        is-deeply @tabs, [], "tabs in $file";
    }
    done-testing;
}
else {
     plan 1;
     skip-rest "Skipping author test";
     exit;
}
