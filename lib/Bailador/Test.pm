use Test;
use Bailador;
use Bailador::Request;
use URI;

module Bailador::Test;

# preparing a environment variale for PSGI
sub get-psgi-response($meth, $url, $data = '') is export {
    die "Invalid method '$meth'" if $meth ne 'GET' and $meth ne 'POST';
	# prefix with http://127.0.0.1:1234 because the URI module cannot handle URI that looks like /foo
    my $uri = URI.new(($url.substr(0, 1) eq '/' ?? 'http://127.0.0.1:1234' !! '') ~ $url);

    my $env = {
        "psgi.multiprocess"    => Bool::False,
        "psgi.multithread"     => Bool::False,
        "psgi.errors"          => IO::Handle.new(path => IO::Special.new(what => "<STDERR>"), ins => 0, chomp => Bool::True),
        "psgi.streaming"       => Bool::False,
        "psgi.nonblocking"     => Bool::False,
        "psgi.version"         => [1, 0],
        "psgi.run_once"        => Bool::False,
        "psgi.url_scheme"      => $uri.scheme,
        "psgi.input"           => $data.encode('utf-8'),
        "HTTP_CACHE_CONTROL"   => "max-age=0",
        "SERVER_PROTOCOL"      => "HTTP/1.1",
        "HTTP_USER_AGENT"      => "Testing",
        "REQUEST_URI"          => $uri.path_query,
        "HTTP_ACCEPT"          => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "HTTP_ACCEPT_ENCODING" => "gzip, deflate, sdch",
        "HTTP_CONNECTION"      => "keep-alive",
        "REQUEST_METHOD"       => $meth,
        "HTTP_HOST"            => $uri.host ~ ':' ~ $uri.port,
        "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.8,he;q=0.6,ru;q=0.4",
        "PATH_INFO"            => $uri.path,
        "SERVER_PORT"          => $uri.port,
        "SERVER_NAME"          => "0.0.0.0",
        "HTTP_COOKIE"          => "",
        "QUERY_STRING"         => $uri.query,
    };
    #my $req = Bailador::Request.new($env);
    return Bailador::dispatch-psgi($env);
}

sub get-response($meth, $path) {
    my $req = Bailador::Request.new_for_request($meth, $path);
    Bailador::dispatch_request($req);
}

#obsolete methods
#sub route-exists($meth, $path, $desc = '') is export {
#    my $req = Bailador::Request.new_for_request($meth, $path);
#    ok Bailador::App.current.find_route($req), $desc;
#}
#
#sub route-doesnt-exist($meth, $path, $desc = '') is export {
#    my $req = Bailador::Request.new_for_request($meth, $path);
#    ok !Bailador::App.current.find_route($req), $desc;
#}

sub response-status-is($meth, $path, $status, $desc = '') is export {
    my $resp = get-response($meth, $path);
    is $resp.code, $status, $desc;
}

sub response-status-isnt($meth, $path, $status, $desc = '') is export {
    my $resp = get-response($meth, $path);
    isnt $resp.code, $status, $desc;
}

sub response-content-is($meth, $path, $cont, $desc = '') is export {
    my $resp = get-response($meth, $path);
    is ~$resp.content, $cont, $desc;
}

sub response-content-isnt($meth, $path, $cont, $desc = '') is export {
    my $resp = get-response($meth, $path);
    isnt ~$resp.content, $cont, $desc;
}

sub response-content-is-deeply($meth, $path, $y, $desc = '') is export {
    my $resp = get-response($meth, $path);
    is_deeply ~$resp.content, $y, $desc;
}

sub response-content-like($meth, $path, $cont, $desc) is export { ... }
sub response-content-unlike($meth, $path, $cont, $desc) is export { ... }

sub response-headers-are-deeply($meth, $path, $cont, $desc) is export { ... }
sub response-headers-include($meth, $path, $cont, $desc) is export { ... }

sub bailador-response($meth, $path, *%opts) is export { ... }

sub read-logs is export { ... }
