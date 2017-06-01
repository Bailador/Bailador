use v6;
use lib 'lib';
use Test;
use Path::Iterator;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>; 

if AUTHOR { 
    # check for use v6;
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

