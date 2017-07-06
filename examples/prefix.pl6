#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;


get "/plain" => sub { "plain" }

prefix '/books' => sub {
    get '/fiction'      => sub { '/books/fiction' }
    get '/nonfiction'   => sub { '/books/nonfiction' }
    prefix '/childrens' => sub {
        get '/alpha' => sub { }
        get '/beta' => sub { }
        get '/gamma' => sub { }
    }
    post get '/fantasy'      => sub { '/books/fantasy' }
}

prefix '/alpha' => sub {
    prefix '/beta' => sub {
        prefix '/gamma' => sub {
            get "/delta" => sub { "ABCD"; }
        }
    }
}

baile();
