use v6.c;

use Bailador;
use Bailador::Route::StaticFile;

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
config.views = $rel_root.IO.child('views').Str;

get '/(.*)' => sub ($url) {
    my $file  = ($url eq '' ?? 'index' !! $url) ~ '.html';
    my $path = $rel_root.IO.child('views').child($file).Str;
    if $path.IO.e {
        return template($file)
    }

    return False;
}

my $files = Bailador::Route::StaticFile.new: directory => $rel_root.IO.child('static'), path => /(.*)/;
app.add_route: $files;
