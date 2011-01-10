use Bailador;

# simple cases
get '/' => sub {
    "hello world"
};

get '/about' => sub {
    "about me"
};

# regexes, as usual
get /foo(.+)/ => sub ($x) {
    "regexes! I got $x"
}

get / '/' (.+) '-' (.+)/ => sub ($x, $y) {
    "$x and $y"
}

# junctions work too
get any('/h', '/help', '/halp') => sub {
    "junctions are cool"
}

bailar;
