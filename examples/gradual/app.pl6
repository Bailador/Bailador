use v6;
use Bailador;

get '/foo' => sub {
    return 'Foo from route';
}

get '/qux' => sub {
    return 'Qux from route';
}



require Bailador::Gradual;

baile;
