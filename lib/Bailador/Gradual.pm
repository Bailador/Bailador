use v6.c;

use Bailador;

# experimental code
# see the examples/gradual/  example
# and the t/30-examples-gradual.t

# Allow app.pl to be in the root of the project or in the bin directory.
# Handle tests propely at least as long they are in the t/ directory.
#my $root = $*PROGRAM.absolute.IO.dirname;
my $rel_root = $*PROGRAM.dirname;
if $rel_root.IO.basename eq 'bin'|'t' {
    $rel_root = '.'; #$rel_root.IO.dirname;
}

# TODO: https://github.com/Bailador/Bailador/issues/169
my $views = 'views';
config.views = $rel_root.IO.child($views).Str;

get '/(.*)' => sub ($url) {
    my $file  = ($url eq '' ?? 'index' !! $url) ~ '.html';
    my $path = $rel_root.IO.child($views).child($file).Str;
    if $path.IO.e {
        return template($file)
    }

    return False;
}

static-dir /(.*)/ => $rel_root.IO.child('static');

