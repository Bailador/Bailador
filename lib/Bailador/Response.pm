class Bailador::Response {
    has $.code     is rw;
    has %.headers  is rw;
    has @.content  is rw;

    method psgi {
        [ $.code, %.headers.list, @.content ]
    }
}
