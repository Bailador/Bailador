use v6.c;
use lib 'lib';

use Path::Finder;
use Test;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

# Enforce that every Perl file (ending with p6, pl6, pm6, or t) will
# have "use v6.c" as the first non-empty line.
# An optional sh-bang  line as the first line is allowed.

my &by = sub ($a, $b) {
    if $a eq 'v6.c' {
        Less;
    } elsif $b eq 'v6.c' {
        More
    }
    elsif $a.starts-with('lib') && ! $b.starts-with('lib') {
        Less
    }
    elsif ! $a.starts-with('lib') && $b.starts-with('lib') {
        More
    }
    elsif ($a.starts-with('Bailador') && ! $b.starts-with('Bailador'))
    {
        More;
    }
    elsif (! $a.starts-with('Bailador') && $b.starts-with('Bailador'))
    {
        Less;
    }
    else
    {
        $a cmp $b;
    }
};

if AUTHOR {
    # check for use v6.c;
    my @dirs = '.';
    for find(@dirs, :skip-vcs, :ext(rx/ ^ ( 'p' <[lm]> 6? | t ) $ /)) -> $file {
        my @lines = $file.lines;
        my @modules;
        for @lines -> $line {
            next if $line eq '#!/usr/bin/env perl6'|'';
            next if $line.starts-with('#');
            if $line ~~ rx/use \s+ ( <-[;]> + ) \s* ';'/ {
                @modules.push: $/.[0].Str;
            } else {
                # first content that is not use. so we're done.
                last
            }
        }
        my $perl-version = @modules[0];
        is $perl-version, 'v6.c', $file.Str ~ ' perl version set to v6.c';
        if $perl-version ne 'v6.c' {
            skip 'module use order', 1;
        }

        my @expected-module-order = @modules.sort: &by;
        is-deeply @modules, @expected-module-order, $file.Str ~ ' module use order';
        #dd @modules;
        #say 'vs';
        #dd @expected-module-order;
        #        like @lines[$expected_line], rx/use \s+ v6(\.c)?/, $file.Str;
    }
    done-testing;
}
else {
     plan 1;
     skip-rest "Skipping author test";
     diag "Skipping author test. Set AUTHOR_TESTING to enable.";
     exit;
}
