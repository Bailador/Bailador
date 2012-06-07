use lib 'lib';

use Bailador;

unless 'data'.IO ~~ :d {
    mkdir 'data'
}

get '/' => sub {
    template 'examples/views/index.tt'
}

post '/new_paste' => sub {
    my $t  = time;
    my $c = request.params<content>;
    unless $c {
        return "No empty pastes please";
    }
    my $fh = open "data/$t", :w;
    $fh.print: $c;
    $fh.close;
    return "New paste available at paste/$t";
}

get /paste\/(.+)/ => sub ($tag) {
    content_type 'text/plain';
    if "data/$tag".IO.f {
        return slurp "data/$tag"
    }
    status 404;
    return "Paste does not exist";
}

baile;
