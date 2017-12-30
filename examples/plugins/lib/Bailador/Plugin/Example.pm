use v6.c;

use Bailador::Plugins;

class Bailador::Plugin::Example:ver<0.001000> is Bailador::Plugin {

    method sample{

        # Because of the inheritage from Bailador::Plugin
        # %.config the config for this plugin Example is available.
        my $param = %.config{'param'};
        return 'Hello I am a sample!';
    }
}
