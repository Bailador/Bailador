use Test;
use Bailador;
use Bailador::Request;
use URI;

unit module Bailador::Test;

# It would be nice to have IO::String here instead
my class IO::Null is IO::Handle {
    multi method print(Str:D \string ) { diag string }
    multi method print(**@args is raw) { diag join '', @args.map: *.Str }

    method print-nl { diag $.nl-out }

    multi method put(Str:D \string)  { diag string ~ $.nl-out }
    multi method put(**@args is raw) {
        diag join '', @args.map(*.Str), $.nl-out
    }

    multi method say(Str:D \string)  { diag string ~ $.nl-out }
    multi method say(**@args is raw) {
        diag join '', @args.map(*.gist), $.nl-out
    }
}

    # preparing a environment variale for PSGI
multi sub get-psgi-response(Bailador::App $app, $meth, $url, $data = '', :$http_cookie = "") is export {
    my $env = get-psgi-env($meth, $url, $data, $http_cookie);
    my $psgi-app = $app.get-psgi-app(),
    my $promise = $psgi-app.($env);
    return de-supply-response $promise.result;
}

multi sub get-psgi-response($meth, $url, $data = '', :$http_cookie = "") is export {
    my $env = get-psgi-env($meth, $url, $data, $http_cookie);
    my $psgi-app = get-psgi-app();
    my $promise = $psgi-app.($env);
    return de-supply-response $promise.result;
}

sub de-supply-response($response) {
    my $body = $response[2];
    if $body ~~ Supply {
        my @result;
        $body.tap(-> $c {@result.push($c);});
        $body.wait;
        return [$response[0], $response[1], |@result];
    }
    die "body must be a Supply";
}

sub get-psgi-env($meth, $url, $data, $http_cookie,) {
    # prefix with http://127.0.0.1:1234 because the URI module cannot handle URI that looks like /foo
    my $uri = URI.new(($url.substr(0, 1) eq '/' ?? 'http://127.0.0.1:1234' !! '') ~ $url);

    my $env = {
        "p6sgi.multiprocess"    => Bool::False,
        "p6sgi.multithread"     => Bool::False,
        "p6sgi.errors"          => IO::Null.new,
        "p6sgi.streaming"       => Bool::False,
        "p6sgi.nonblocking"     => Bool::False,
        "p6sgi.version"         => [1, 0],
        "p6sgi.run_once"        => Bool::False,
        "p6sgi.url_scheme"      => $uri.scheme,
        "p6sgi.input"           => $data.encode('utf-8'),
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
        "HTTP_COOKIE"          => $http_cookie,
        "QUERY_STRING"         => $uri.query,
    };

}


#sub get-response($meth, $path) {
#    my $req = Bailador::Request.new_for_request($meth, $path);
#    Bailador::dispatch_request($req);
#}

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

#sub response-status-is($meth, $path, $status, $desc = '') is export {
#    my $resp = get-response($meth, $path);
#    is $resp.code, $status, $desc;
#}
#
#sub response-status-isnt($meth, $path, $status, $desc = '') is export {
#    my $resp = get-response($meth, $path);
#    isnt $resp.code, $status, $desc;
#}

#sub response-content-is($meth, $path, $cont, $desc = '') is export {
#    my $resp = get-response($meth, $path);
#    is ~$resp.content, $cont, $desc;
#}
#
#sub response-content-isnt($meth, $path, $cont, $desc = '') is export {
#    my $resp = get-response($meth, $path);
#    isnt ~$resp.content, $cont, $desc;
#}
#
#sub response-content-is-deeply($meth, $path, $y, $desc = '') is export {
#    my $resp = get-response($meth, $path);
#    is_deeply ~$resp.content, $y, $desc;
#}
#
#sub response-content-like($meth, $path, $cont, $desc) is export { ... }
#sub response-content-unlike($meth, $path, $cont, $desc) is export { ... }

#sub response-headers-are-deeply($meth, $path, $cont, $desc) is export { ... }
#sub response-headers-include($meth, $path, $cont, $desc) is export { ... }

#sub bailador-response($meth, $path, *%opts) is export { ... }

sub read-logs is export { ... }
