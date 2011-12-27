use Bailador;

get post '/' => sub {
    if request.is_get {
        return "I am GET"
    } else {
        return [request.params.perl, request.content_type,
                request.content_length]
    }
}

baile;
