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

get '/sitemap.xml' => sub {
    my $r = request();

    # TODO: get the list if fixed routes
    my @pages;
    my @entries = ($views);
    while @entries {
        my $thing = shift @entries;
        my $path = $rel_root.IO.child($thing);
        if $path.IO.d {
            my @things = $path.dir;
            @entries.append(@things.map({ "$_" }));
            next;
        }
        if $path.IO.f and $path ~~ /\.html$/ {
             if $path ~~ /\/index\.html$/ {
                 @pages.append($thing.substr(1 + $views.chars, *-10));
             } else {
                 @pages.append($thing.substr(1 + $views.chars));
             }
             next;
        }
        # TODO: report or just skip?
    }
    my $dt = DateTime.now;

    my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>\n};
    $xml ~= qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n};

    for @pages -> $page {
        $xml ~= qq{  <url>\n};
        $xml ~= sprintf('    <loc>%s/%s</loc>', $r.url_root, $page) ~ "\n";
        $xml ~= sprintf('    <lastmod>%s</lastmod>', $dt.yyyy-mm-dd ) ~ "\n";
        #$xml ~= qq{    <changefreq>monthly</changefreq>\n};
        #$xml ~= qq{    <priority>0.8</priority>\n};
        $xml ~= qq{  </url>\n};
    }
    $xml ~= qq{</urlset>\n};

    content_type('text/xml');
    return $xml;
}



get '/(.*)' => sub ($url) {
    #if $url eq 'index' or $url eq 'index.html' {
    #    redirect('/');
    #}

    my $file  = $url;
    my $tmp_path = $rel_root.IO.child($views).child($url).Str;

    if $tmp_path.IO.e and $tmp_path.IO.d {
        $file = $url ~ 'index';
    }
    $file ~= '.html';

    my $path = $rel_root.IO.child($views).child($file).Str;

    if $path.IO.e {
        return template($file)
    }

    return False;
}

static-dir /(.*)/ => $rel_root.IO.child('static');

