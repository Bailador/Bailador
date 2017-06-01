use v6;
use lib 'lib';
use Test;
use Path::Iterator;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if AUTHOR {
    # check for use v6;
    my @dirs = '.';
    for Path::Iterator.skip-vcs.ext(rx/ ^ ( 'p' <[lm]> 6? | t ) $ /).in(@dirs) -> $file {
        my @lines = $file.IO.lines.grep(rx/\s$/);
        is-deeply @lines, [], $file;
    }
    done-testing;
}
else {
     plan 1;
     skip-rest "Skipping author test";
     exit;
}

