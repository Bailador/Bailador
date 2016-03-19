use v6;

use lib 'lib';

use Test;

plan 2;

use Bailador;
ok 1, "'use Bailador' worked !";

use-ok 'Bailador';
