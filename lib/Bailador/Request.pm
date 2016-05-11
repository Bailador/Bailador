class Bailador::Request {

    has $.env is rw;
    has %!cookies;
    has %!headers;

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
        my Str $source_data;
        given $source {
            when 'query' {
                $source_data = $.env<QUERY_STRING> if $!env<QUERY_STRING>;
            }
            when 'body' {
                $source_data = $.env<p6sgi.input>.decode if $!env<p6sgi.input>;
            }
            default {
                die "unknown source '$source'";
            }
        }
        return %ret unless $source_data.defined;

        for $source_data.split('&') -> $p {
            my @pair = $p.split('=', 2);
            if (%ret{@pair[0]}:exists) {
                %ret.push((@pair[0] => |uri_unescape(@pair[1])));
            }
            else {
                %ret{@pair[0]} = uri_unescape @pair[1];
            }
        }

        return %ret;
    }

    method headers () {
        return %!headers if %!headers;
        for $.env.keys.grep(rx:i/^[HTTP||CONTENT]/) -> $key {
            my $field = S:i/HTTPS?_// given $key;
            %!headers{$field.uc} = $.env{$key};
        }
        return %!headers;
    }

    method cookies () {
        return %!cookies if %!cookies || !$.env<HTTP_COOKIE>;
        for $.env<HTTP_COOKIE>.split(/<[;,]>\s/) -> $cookie {
            my ($name, $value) = $cookie.trim.split(/\s*\=\s*/, 2);
            my @values;
            if $value {
                @values = $value.split(/<[&;]>/).map: { uri_unescape($_) };
            }
            # TODO: build Bailador::Cookie object :)
            %!cookies{uri_unescape($name)} = @values;
        }
        return %!cookies;
    }

    method is_ajax returns Bool {
        return True if $.header<X-REQUESTED-WITH>:exists
                    && $.header<X-REQUESTED-WITH> eq 'XMLHttpRequest';
        return False;
    }

    method new_for_request($meth, $path) {
        my $path_info = $path.split('?')[0];
        self.new: env => { REQUEST_METHOD => $meth, REQUEST_URI => $path, PATH_INFO => $path_info }
    }

    method reset ($env) {
        $!env = $env;
        %!cookies = ();
        %!headers = ();
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
    method is_patch    { self.method eq 'PATCH'  }

    method content_type   { $.env<CONTENT_TYPE>   }
    method content_length { $.env<CONTENT_LENGTH> }

    # TODO Shouldn't ignore Content-Type
    method body           { $.env<p6sgi.input>.decode }

    # in Dancer2, these are inherited from Plack::Request
    method user_agent  { $.headers<USER_AGENT>    }
    method referer     { $.headers<REFERER>       }
    method address     { $.env<REMOTE_ADDR>      }
    method remote_host { $.env<REMOTE_HOST>      }
    method protocol    { $.env<SERVER_PROTOCOL>  }
    method user        { $.env<REMOTE_USER>      }
    method script_name { $.env<SCRIPT_NAME>      }
}
