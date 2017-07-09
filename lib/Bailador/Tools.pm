use v6.c;

unit module Bailador::Tools;

sub get-app-root(--> IO) is export {
    # cache the $app-dir
    state $app-dir = {
        my $app-root;
        if %*ENV<BAILADOR_APP_ROOT>:exists {
            $app-root = %*ENV<BAILADOR_APP_ROOT>.IO.resolve;
        } else {
            my $parent = $*PROGRAM.parent.resolve;
            $app-root = $parent.basename eq 'bin' ?? $parent.parent !! $parent;
        }
        $app-root;
    }.();
    return $app-dir;
}
