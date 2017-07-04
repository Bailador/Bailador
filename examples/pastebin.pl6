#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use Bailador;

unless 'data'.IO ~~ :d {
    mkdir 'data'
}

get '/' => sub {
    template 'index.tt'
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
    return qq{New paste available at <a href="paste/$t">paste/$t\</a>};
}

get /paste\/(\d+)$/ => sub ($tag) {
    content_type 'text/plain';
    if "data/$tag".IO.f {
        return slurp "data/$tag"
    }
    status 404;
    return "Paste does not exist";
}

baile();
