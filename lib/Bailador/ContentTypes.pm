use v6.c;

unit module Bailador::ContentTypes;

my %mapping = (
    appcache => 'text/cache-manifest',
    atom     => 'application/atom+xml',
    bin      => 'application/octet-stream',
    css      => 'text/css',
    gif      => 'image/gif',
    gz       => 'application/x-gzip',
    htm      => 'text/html',
    html     => 'text/html;charset=UTF-8',
    ico      => 'image/x-icon',
    jpeg     => 'image/jpeg',
    jpg      => 'image/jpeg',
    js       => 'application/javascript',
    json     => 'application/json;charset=UTF-8',
    mp3      => 'audio/mpeg',
    mp4      => 'video/mp4',
    ogg      => 'audio/ogg',
    ogv      => 'video/ogg',
    pdf      => 'application/pdf',
    png      => 'image/png',
    rss      => 'application/rss+xml',
    svg      => 'image/svg+xml',
    txt      => 'text/plain;charset=UTF-8',
    webm     => 'video/webm',
    woff     => 'application/font-woff',
    xml      => 'application/xml',
    zip      => 'application/zip',
    pm       => 'application/x-perl',
    pm6      => 'application/x-perl',
    pl       => 'application/x-perl',
    pl6      => 'application/x-perl',
    p6       => 'application/x-perl',

    fallback => 'application/octet-stream'
);

multi sub detect-type(IO::Path $file) returns Str is export {
    my $ext = $file.extension.lc;
    if %mapping{$ext}:exists {
        return %mapping{$ext};
    } else {
        return %mapping<fallback>;
    }
}

multi sub detect-type($result) returns Str is export {
    if $result ~~ Str {
        return %mapping<html>;
    } else {
        return %mapping<fallback>;
    }
}
