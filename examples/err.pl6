#!/usr/bin/env perl6

use v6.c;
use lib 'lib';
use Bailador;

#app.config.mode = 'development';

get '/' => sub {
    q{
<h2>Welcome to Bailador!</h2>
<ul>
   <li><a href="/page_404">404</a></li>
   <li><a href="/die">Throw an exception</a></li>
</ul>
};
}

get '/die' => sub {
    die 'This is an exception so you can see how it is handled';
    "hello world"
}

error 404 => sub {
    return 'This is our custom 404 handler';
}

error 500 => sub {
    return 'This is our custom 500 handler';
}

baile();
