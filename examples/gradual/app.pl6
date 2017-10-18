use v6.c;
use Bailador;

get '/foo' => sub {
    return 'Foo from route';
}

get '/qux' => sub {
    return 'Qux from route';
}



require Bailador::Feature::Gradual;

baile;
