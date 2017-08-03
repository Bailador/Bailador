use v6.c;

unit module Test::Helpers;

sub wait-port(int $port, Str $host='0.0.0.0', :$sleep=0.1, int :$times=600) is export {
    LOOP: for 1..$times {
        try {
            my $sock = IO::Socket::INET.new(:host($host), :port($port));
            $sock.close;

            CATCH { default {
                sleep $sleep;
                next LOOP;
            } }
        }
        return;
    }

    die "$host:$port doesn't open in {$sleep*$times} sec.";
}

sub req(Str $req, $port) is export {
    my $client = IO::Socket::INET.new(:host<0.0.0.0>, :port($port));
    my $data   = '';
    $client.print($req);
    sleep .5;
    while my $d = $client.recv {
        $data ~= $d;
    }
    CATCH { default { "CAUGHT {$_}".say; } }
    try { $client.close; CATCH { default { } } }
    return $data;
}
