use v6.c;

use Log::Any::Adapter;

class Bailador::Log::Adapter is Log::Any::Adapter {
    has $.io-handle is rw;

    method handle($msg) {
      given $.io-handle {
        when Supplier {
          $.io-handle.emit: $msg;
        }
        default {
          $.io-handle.say: $msg;
        }
      }
    }
}
