use v6;

use HTTP::Request::Supply;
use HTTP::Status;
# TODO use IO::Socket::Async::SSL;

class Bailador::Server {
    has $.host is required;
    has Int $.port is required;
    has $.app is required;

    constant CRLF = "\x0D\x0A";

    method run() {
        react {
            whenever IO::Socket::Async.listen($.host, $.port) -> $conn {
                my $envs = HTTP::Request::Supply.parse-http($conn.Supply(:bin));
                whenever $envs -> %env {
                    my $result = await $.app.(%env);
                    self!handle-response($result, $conn);
                }
            }
        }
    }

    method !handle-response($result, $conn) {
        my $http-status = $result[0];
        my @http-header = $result[1].flat;
        my $body-supply = $result[2];

        my $protocol = 'HTTP/1.0';
        my $http-msg = get_http_status_msg($http-status);

        $conn.print("$protocol $http-status $http-msg" ~ CRLF);
        for @http-header -> $header {
            $conn.print($header.key ~ ': ' ~ $header.value ~ CRLF);
        }
        $conn.print(CRLF);
        $body-supply.tap(
            -> $chunk {
                if $chunk ~~ Str {
                    $conn.print($chunk);
                } elsif $chunk ~~ Blob {
                    $conn.write($chunk);
                } else {
                    X::NYI.new(feature => 'handle chunk types differend to Blob and Str').thorw;
                }
            }
        );
        $body-supply.wait;
        $conn.close();
    }
}
