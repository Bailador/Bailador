use v6.c;

use Terminal::ANSIColor;

use Bailador::Configuration;

unit module Bailador::Utils;

# Colorize the terminal output with the given color, only if terminal-color setting is set to True.
multi sub terminal-color(Str $text, Str $color, Bailador::Configuration $config) is export {
    if $config.terminal-color {
        say color($color), $text;
    } else {
        say $text;
    }
}
