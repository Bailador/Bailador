class Bailador::Request {
    use URI::Escape;

    has $.env is rw;

    method params {
        my %ret;
        for $.env<psgi.input>.split('&') -> $p {
            my $pair = $p.split('=');
            %ret{$pair[0]} = uri_unescape $pair[1];
        }
        return %ret;
    }

    method new_for_request($meth, $path) {
        self.new: env => { REQUEST_METHOD => $meth, REQUEST_URI => $path}
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
    method body           { $.env<psgi.input>     }
}
