class Bailador::Response {
    has $.code     is rw;
    has %.headers  is rw;
    has @.content  is rw;
    has @.cookies  is rw;

    method psgi {
        my @headers = %.headers.list;
        for @.cookies { @headers.push("Set-Cookie" => $_) }
        [ $.code, [ @headers ], |@.content ]
    }
}
