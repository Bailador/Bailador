class Bailador::Environment is Hash {

    method !fetch-value(Str:D $key) {
        my @p6w-prefixes = <<p6w p6sgi psgi>>;
        for @p6w-prefixes -> $prefix {
            my $k = $prefix ~ '.' ~ $key;
            return self{$k} if self{$k}:exists;
        }
        return Any;
    }

    method p6w-body-encoding {
        return self!fetch-value('body.encoding');
    }
    method p6w-errors {
        return self!fetch-value('errors');
    }
    method p6w-input {
        return self!fetch-value('input');
    }
    method p6w-multiprocess {
        return self!fetch-value('multiprocess');
    }
    method p6w-multithread {
        return self!fetch-value('multithread');
    }
    method p6w-protocol {
        return self!fetch-value('protocol');
    }
    method p6w-protocol-enabled {
        return self!fetch-value('protocol.enabled');
    }
    method p6w-protocol-support {
        return self!fetch-value('protocol.support');
    }
    method p6w-ready {
        return self!fetch-value('ready');
    }
    method p6w-run-once {
        return self!fetch-value('run-once');
    }
    method p6w-url-scheme {
        return self!fetch-value('url-scheme');
    }
    method p6w-version {
        return self!fetch-value('version');
    }
}
