use v6.c;

use Bailador;

get '/bailador' => sub {
    my %status =
        running => 'ok';

    return to-json %status;
}
