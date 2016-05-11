use HTTP::MultiPartParser;
use Bailador::Request::Multipart;

class Bailador::Request {

    has $.env is rw;
    has %!cookies;
    has %!headers;
    has %!params;

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
        unless %!params {
            my %ret = self.params('query');
            %ret = |%ret, self.params('body');
            %!params = %ret;
        }
        return %!params;
    }
    multi method params ($source) {
        my %ret;
        my Str $source_data;
        given $source {
            when 'query' {
                %ret = self!parse-urlencoded: $.env<QUERY_STRING> if $!env<QUERY_STRING>;
            }
            when 'body' {
                my $headers = self.headers;
                my regex bcharnospace { <[0..9]> || <[ a..z  A..Z]> || "'" || '(' || ')' || '+' || '_' || ',' || '-' || '.'  || '/' || ':' || '=' || '?' };
                if not $headers<CONTENT_TYPE>:exists or $headers<CONTENT_TYPE>:exists and $headers<CONTENT_TYPE>.starts-with("application/x-www-form-urlencoded") {
                    %ret = self!parse-urlencoded: $.env<p6sgi.input>.decode if $!env<p6sgi.input>;
                }
                # boundary according to RFC 1341
                #
                # The only mandatory parameter for the multipart Content-Type is the boundary parameter, which
                # consists of 1 to 70 characters from a set of characters known to be very robust through email
                # gateways, and NOT ending with white space. (If a boundary appears to end with white space,
                # the white space must be presumed to have been added by a gateway, and should be deleted.)
                # It is formally specified by the following BNF:
                #
                # boundary := 0*69<bchars> bcharsnospace
                # bchars := bcharsnospace / " "
                # bcharsnospace :=    DIGIT / ALPHA / "'" / "(" / ")" / "+" / "_"
                # / "," / "-" / "." / "/" / ":" / "=" / "?"

                elsif $headers<CONTENT_TYPE>:exists and $headers<CONTENT_TYPE> ~~ / 'multipart/form-data;'  .* 'boundary' '=' '"' ? ( <bcharnospace> ** 0..69  ) \s* '"' ? / {
                    my $boundary = $/[0].Str;
                    %ret = self!parse-multipart: $.env<p6sgi.input>, $boundary.encode;
                }
            }
            default {
                die "unknown source '$source'";
            }
        }
        return %ret;
    }

    method !parse-urlencoded(Str $encoded) {
        my %ret;
        for $encoded.split('&') -> $p {
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

    method !parse-multipart(Blob $formdata, Blob $boundary) {
        my %result;
        my %headers;
        my $error;

        my Blob $content = Blob.new;
        my $parser = HTTP::MultiPartParser.new(
            boundary => $boundary,
            on_header => sub (@headers) {
                for @headers -> $header {
                    if $header ~~ m/ ^ ( \S+ ) ':' \s+ (.+) $ / {
                        %headers{ $/[0].Str.uc } = $/[1].Str;
                    }
                }
            },
            on_body => sub (Blob $chunk, Bool $final) {
                $content ~= $chunk;
                if $final {
                    my $multipart = Bailador::Request::Multipart.new(:$content, :%headers);
                    my $name = $multipart.name;
                    %result{$name} = $multipart;
                }
            },
            on_error => sub (Str $message) {
                $error = $message;
            }
        );

        $parser.parse($formdata);
        $parser.finish();

        if $error {
            note $error;
            return Hash;
        }

        return %result;
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
        %!params  = ();
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
