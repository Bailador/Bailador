use v6.c;
use lib 'lib';

use Test;

plan 1;

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if AUTHOR {
    require Test::META <&meta-ok>;
    meta-ok;
    done-testing;
}
else {
     skip-rest "Skipping author test";
     diag "Skipping author test. Set AUTHOR_TESTING to enable.";
     exit;
}
