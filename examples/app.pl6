#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Bailador;
use Bailador::Route::StaticFile;

app.config.mode = 'development';

# simple cases
get '/' => sub {
    q{
<h2>Welcome to Bailador!</h2>
<ul>
   <li><a href="/red">Redirect to not existing page</a></li>
   <li><a href="/die">Throw an exception</a></li>
   <li><a href="/about">Simple text</a></li>
   <li><a href="/hello/Foo Bar">Say hello</a></li>
   <li><a href="/fooBarMoo">Routing</a></li>
   <li><a href="/one-two-three">Routing</a></li>
   <li><a href="/template/abc">Use a template</a></li>
</ul>
};
}

get '/red' => sub {
    redirect('/index.html');
}

get '/die' => sub {
    die 'This is an exception so you can see how it is handled';
    "hello world"
}

get '/about' => sub {
    "about me"
}

get '/hello/:name' => sub ($name) {
    "Hello $name!"
};

get '/info' => sub {
    say %*ENV<P6SGI_CONTAINER>;
    say %*ENV<P6SGI_CONTAINER>.WHAT;
    say %*ENV<PERL6_PROGRAM_NAME>;
    say %*ENV<PERL6_PROGRAM_NAME>.WHAT;
}

# regexes, as usual
get /foo(.+)/ => sub ($x) {
    "regexes! I got $x"
}

get rx{ '/' (.+) '-' (.+) } => sub ($x, $y) {
    "$x and $y"
}

# templates!
get / ^ '/template/' (.+) $ / => sub ($x) {
    template 'tmpl.tt', { name => $x }
}

get '/env' => sub {
    my Str $result;
    for request.env.sort(*.key)>>.kv -> ($k, $v) {
        $result ~= "$k\t" ~ $v.perl ~ "\n";
    }
    app.render: content => $result, type => 'text/plain';
    $result;
}

app.add_route: Bailador::Route::StaticFile.new: directory => $?FILE.IO.parent.child('public'), path => / (.*) /;

prefix '/media' => sub {
    prefix '/video' => sub { 
        get '/dvds' => sub { 'DVDS' }
        get '/VHS'  => sub { 'VHS' }
    }
    prefix '/music' => sub {
        get '/cds'  => sub { 'CDS' }
        get '/mp3'  => sub { 'MP3' }
    }
    get '/art'      => sub { 'art' }
    get '/movies'   => sub { 'movies' }
}

baile();
