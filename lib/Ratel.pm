# this will live here while it does not have its own repo
#
# this file is not written by me and the 'beer for unreadable Perl'
# challenge does not apply to this file

class Ratel {
    has $.source;
    has $.compiled;
    has @!hunks;
    has %.transforms is rw;

    method new (*%args) {
        my $self = self.bless(*, |%args);
        $self.initialize;
        return $self;
    }

    method initialize {
        # XXX Needs to be re-thought to allow wrapping the contents
        # of the unquote, use parameterized delims, etc...
        %!transforms{'='} = -> $a {"print $a"};
        %!transforms{'!'} = -> $a {'print %attrs<' ~ $a ~ '>'};
        self.source($.source) if defined $.source;
    }

    multi method load(Str $filename) {
        self.source(slurp($filename));
    }

    multi method source() {
        return $!source;
    }
    multi method source(Str $text) {
        my $index = 0;
        $!source = $text;
        my $source = '%]' ~ $text ~ '[%';
        for %!transforms.kv -> $k, $v {
            $source.=subst(rule {'[%'$k ([<!before '%]'>.]*) '%]'}, -> $match {'[%' ~ $v($match[0]) ~ '%]'}, :g);
        }
        @!hunks = $source.comb(rule {'%]' ([<!before '[%'>.]*) '[%'});
        @!hunks>>.=subst(/^'%]' ([<!before '[%'>.]*) '[%'$/, -> $m { $m[0] }, :g);
        $!compiled
            = $source.subst(/('%]' [<!before '[%'>.]* '[%')/,
                            {";\$.emit-hunk({$index++});"},
                            :g);
        return;
    }

    method emit-hunk(Int $i) {
        $.emit(@!hunks[$i][0]);
    }
    method emit($m) {
        $*result ~= $m;
    }

    method render(*%attrs) {
        my $*result = '';
        my $obj = self;
        # XXX Needs cleanup...
        my $*OUT = (class {
                method say(*@args) {
                    $obj.emit($_) for (@args, "\n");
                }
                method print(*@args) {
                    $obj.emit($_) for @args;
                }
            }).new();;
        eval $!compiled;
        return $*result;
    }
}
