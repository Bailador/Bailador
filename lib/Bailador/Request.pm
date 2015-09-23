class Bailador::Request {

    has $.env is rw;

    sub uri_unescape ($uri) {
        use URI::Escape;
        my $decoded;
        try {
            $decoded = uri_unescape($uri);
            CATCH {
                when X::AdHoc {
                    $decoded = uri_unescape($uri, :no_utf8);
                }
            }
        }
        $decoded;
    }

    multi method params () {
        # Dancer2 also mixes GET and POST params and overwrites the GET params by the POST params
        my %ret = self.params('query');
        %ret = |%ret, self.params('body');

        return %ret;
    }
    multi method params ($source) {
        my %ret;
        given $source {
            when 'query' {
                if $!env<QUERY_STRING> {
                    for $.env<QUERY_STRING>.split('&') -> $p {
                        my $pair = $p.split('=', 2);
                        %ret{$pair[0]} = uri_unescape $pair[1];
                    }
                }
            }
            when 'body' {
                if $!env<psgi.input> {
                    for $.env<psgi.input>.decode.split('&') -> $p {
                        my $pair = $p.split('=', 2);
                        %ret{$pair[0]} = uri_unescape $pair[1];
                    }
                }
            }
            default {
                die "unknown source '$source'";
            }
        }

        return %ret;
    }

    method cookies () {
        my %ret;
        if $.env<HTTP_COOKIE> {
            for $.env<HTTP_COOKIE>.split('; ') {
                my ($name, $value) = $_.split('=', 2);
                %ret{uri_unescape($name)} = uri_unescape($value);
            }
        }
        return %ret;
    }

    method new_for_request($meth, $path) {
        my $path_info = $path.split('?')[0];
        self.new: env => { REQUEST_METHOD => $meth, REQUEST_URI => $path, PATH_INFO => $path_info }
    }

    method port        { $.env<SERVER_PORT>      }
    method request_uri { $.env<REQUEST_URI>      }
    method uri         { self.request_uri        }
    method path        { $.env<PATH_INFO>        }

    method method      { $.env<REQUEST_METHOD>   }
    method is_get      { self.method eq 'GET'    }
    method is_post     { self.method eq 'POST'   }
    method is_put      { self.method eq 'PUT'    }
    method is_delete   { self.method eq 'DELETE' }
    method is_head     { self.method eq 'HEAD'   }
    method is_patch    { self.method eq 'PATCH' }

    method content_type   { $.env<CONTENT_TYPE>   }
    method content_length { $.env<CONTENT_LENGTH> }

    # TODO Shouldn't ignore Content-Type
    method body           { $.env<psgi.input>.decode }
}
