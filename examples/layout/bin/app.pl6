use v6.c;
use Bailador;

get '/' => sub {
    template 'main.tt', { title => 'Hello Layout' };
}

get '/other' => sub {
    template 'main.tt', :layout('other.tt'), { title => 'Using Other Layout' };
}

baile;

