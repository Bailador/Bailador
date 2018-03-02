use v6.c;

use Test;

use Bailador;
use Bailador::Test;

plan 8;

## Test default configuration
subtest {
    plan 11;

    my $app = Bailador::App.new;
    isa-ok $app, Bailador::App;

    my $config = $app.config;
    isa-ok $config, Bailador::Configuration;

    is $config.mode, 'production', 'Default mode is production';
    is $config.host, '127.0.0.1', 'Default host is 127.0.0.1';
    is $config.port, 3000, 'Default port is 3000';

    is $config.config-file, 'settings.yaml', 'Default configuration filename is settings.yaml';

    is $config.cookie-name, 'bailador', 'Default cookie name is bailador';
    is $config.cookie-path, '/', 'Default cookie path is /';
    is $config.cookie-expiration, 3600, 'Default cookie expiration is 3600';
    is $config.hmac-key, 'changeme', 'Default hmac-key is changeme';
    is $config.backend, 'Bailador::Sessions::Store::Memory', 'Default backend is Bailador::Sessions::Store::Memory';
}

my $file = "t/settings.yaml";

my $content = q:to/EOT/;
mode: 'development'
host: 'localhost'
port: 8080

cookie-name: 'Bailador-cookie'
cookie-expiration: 2800
EOT

END {
    # remove the file after the tests
    unlink $file;
}

spurt $file, $content;

# test 2
## Test configuration from a file
subtest {
    plan 10;

    my $app = Bailador::App.new;
    isa-ok $app, Bailador::App;

    $app.load-config();
    my $config = $app.config;
    isa-ok $config, Bailador::Configuration;

    is $config.mode, 'development', 'Mode from configuration file is development';
    is $config.host, 'localhost', 'Host from configuration file is localhost';
    is $config.port, 8080, 'Port from configuration file is 8080';

    is $config.cookie-name, 'Bailador-cookie', 'Cookie name is now Bailador-cookie';
    is $config.cookie-path, '/', 'Cookie path is still /';
    is $config.cookie-expiration, 2800, 'Cookie expiration is now 2800';
    is $config.hmac-key, 'changeme', 'Hmac-key is still changeme';
    is $config.backend, 'Bailador::Sessions::Store::Memory', 'Backend is still Bailador::Sessions::Store::Memory';
}

## Test configuration ENV must override settings.yaml
subtest {
    plan 5;
    # Prepare ENV
    temp %*ENV<BAILADOR> = 'port:9090';

    my $app = Bailador::App.new;
    isa-ok $app, Bailador::App;

    $app.location( $*PROGRAM.parent.absolute );
    $app.load-config();

    my $config = $app.config;
    isa-ok $config, Bailador::Configuration;

    is $config.mode, 'development', 'Mode from configuration file is development';
    is $config.host, 'localhost', 'Host from configuration file is localhost';
    is $config.port, 9090, 'Port from configuration from ENV is 9090 - override settings.yaml';
}

## Change config dir relative to application location
subtest {
    plan 2;

    temp %*ENV<BAILADOR_CONFIGDIR> = 'config';

    my $app = Bailador::App.new;
    $app.location( $*PROGRAM.parent.absolute );
    $app.load-config();
    my $config = $app.config;

    is $config.port, 9090, 'Port from alternate config directory is 9090';
    is $config.host, 'www.example.com', 'Host from alternate config directory is www.example.com';
}

## Change config dir absolute
subtest {
    plan 2;

    temp %*ENV<BAILADOR_CONFIGDIR> = $*PROGRAM.parent.child("config").absolute;

    my $app = Bailador::App.new;
    $app.location( $*PROGRAM.parent.absolute);
    $app.load-config();
    my $config = $app.config;

    is $config.port, 9090, 'Port from absolute alternate config directory is 9090';
    is $config.host, 'www.example.com', 'Host from absolute alternate config directory is www.example.com';
}

## Specify config file relative to application location
subtest {
    plan 2;

    temp %*ENV<BAILADOR_CONFIGFILE> = 'config/config.yaml';

    my $app = Bailador::App.new;
    $app.location( $*PROGRAM.parent.absolute );
    $app.load-config();
    my $config = $app.config;

    is $config.host, 'localhost', 'Host from relative config file is localhost';
    is $config.name, 'Fred', 'Name from relative config file is Fred';
}

## Specify absolute config file
subtest {
    plan 2;

    temp %*ENV<BAILADOR_CONFIGFILE> = $*PROGRAM.parent.child("config").child('config.yaml').absolute;

    my $app = Bailador::App.new;
    $app.location( $*PROGRAM.parent.absolute );
    $app.load-config();
    my $config = $app.config;

    is $config.host, 'localhost', 'Host from absolute config file is localhost';
    is $config.name, 'Fred', 'Name from absolute config file is Fred';
}

## Settings in -local override
subtest {
    plan 1;

    temp %*ENV<BAILADOR_CONFIGFILE> = 'config/config.yaml';

    my $app = Bailador::App.new;
    $app.location( $*PROGRAM.parent.absolute );
    $app.load-config();
    my $config = $app.config;

    is $config.port, 9999, 'Port from alternate config directory is 9999';
}
