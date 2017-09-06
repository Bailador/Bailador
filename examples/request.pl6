#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use Bailador;


# simple cases
get '/.*' => sub {
    my $r = request;
    my $html = "Show the parameters of the request object<b><hr>\n";
    $html ~= "<table>\n";
    for <
        port
        server
        request_uri
        uri
        path

        method
        is_get
        is_post
        is_put
        is_delete
        is_head
        is_patch

        content_type
        content_length

        script_name

        body

        user_agent
        referer
        address
        remote_host
        protocol
        user
        scheme
    >  -> $f {
        $html ~= sprintf('<tr><td>%s</td><td>%s</td></tr>', $f, ($r."$f"() // ''));
    }
    $html ~= "</table>\n";

    $html ~= '<hr>For further examples see <a href="http://127.0.0.1:3000/abc?x=42">this url</a> for examples.';
    return $html;
}
baile();

