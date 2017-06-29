use v6.c;

use Path::Iterator;
use Test;

use lib 'lib';


constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

# Enforce that every Perl file (ending with p6, pl6, pm6, or t) will
# have "use v6;" or "use v6.c" as the first non-empty line.
# An optional sh-bang  line as the first line is allowed.

if AUTHOR {
    # check for use v6.c;
    my @dirs = '.';
    for Path::Iterator.skip-vcs.ext(rx/ ^ ( 'p' <[lm]> 6? | t ) $ /).in(@dirs) -> $file {
        my @lines = $file.IO.lines;
        my $expected_line = 0;
        if @lines[0] eq '#!/usr/bin/env perl6' {
            $expected_line = 1;
        }
        $expected_line++ while @lines[$expected_line] eq '';
        like @lines[$expected_line], rx/use \s+ v6(\.c)?/, $file.Str;
    }
    done-testing;
}
else {
     plan 1;
     skip-rest "Skipping author test";
     exit;
}
