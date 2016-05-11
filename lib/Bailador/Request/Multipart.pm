class Bailador::Request::Multipart {
    ## Content-Disposition: form-data; name="file"; filename="xxx.png"
    ## Content-Type: image/png
    has Blob $.content;
    has %.headers;

    has Bool $!is_parsed;
    has Str $!filename;
    has Str $!name;

    method !parse_headers {
        my $content-disposition = %.headers<CONTENT-DISPOSITION>;
        die "CONTENT-DISPOSITION header is required for multipart/form-data " ~ %.headers.perl unless $content-disposition;
        if $content-disposition ~~ / << name >> '=' '"' ( <-["]>+ ) '"' / {
            $!name = $/[0].Str;
        }
        if $content-disposition ~~ / << filename >> '=' '"' ( <-["]>+ ) '"' / {
            $!filename = $/[0].Str;
        }

        $!is_parsed = True;
    }

    method filename {
        self!parse_headers unless $!is_parsed;
        return $!filename;
    }

    method name {
        self!parse_headers unless $!is_parsed;
        return $!name;
    }

    method is_upload {
        return so self.filename;
    }

    method size {
        return $.content.elems;
    }

    method Str {
        return $.content.decode;
    }
}
