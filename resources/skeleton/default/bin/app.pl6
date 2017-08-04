use v6.c;
use Bailador;

my $version = '0.0.1';

get '/' => sub {
    template 'index.html', { version => $version }
}

baile();
