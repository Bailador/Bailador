use v6.c;

use Log::Any::Adapter;

class Bailador::LogAdapter is Log::Any::Adapter {
    has $.io-handle is rw;

    method handle($msg) {
        $.io-handle.say: $msg;
    }
}
