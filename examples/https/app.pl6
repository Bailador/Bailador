#!/usr/bin/env perl6
use v6.c;
use lib 'lib';
use Bailador;

app.config.default-content-type = 'application/json';
app.config.default-command      = 'ogre';
app.config.tls-mode             = True;
app.config.tls-config           = (
    certificate-file => 'certs/cert.pem',
    private-key-file => 'certs/key.pem',
);

get '/' => sub {
    'This is served via https from HTTP::Server::Ogre'
}

baile();
