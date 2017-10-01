use v6.c;

use Log::Any::Formatter;
use Terminal::ANSIColor;

class Bailador::LogFormatter is Log::Any::Formatter {
    has %.colors is required;
    has $.log-any-formatter;
    has $.colorize;

    submethod BUILD(
        :$!colorize,
        :$format,
        :%!colors,
        :$!log-any-formatter = Log::Any::FormatterBuiltIN.new(:format($format))
    ) {}

    method format(|param) {
        my $str      = $.log-any-formatter.format(|param);
        my $override = param<extra-fields><color>;
        my $severity = param<severity>;
        my $color    = $override || %.colors{ $severity };
        return $color ?? colored($str, $color) !! $str;
    }
}
