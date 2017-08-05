use v6.c;

# Log::Any v 0.9.4 introduces extra-fields.
use Log::Any::Formatter:ver('0.9.4');

# class A2-Formatter is Log::Any::Formatter {
#   my @res;
#   has $.format;
#   method format( :$date-time, :$msg!, :$category!, :$severity!, :%extra-fields ) {
#     $!format.format( %extra-fields, @res, 0, $date-time, DateTime.now );
#   }
# }

class Bailador::LogFormatter is Log::Any::Formatter {
  has $.format = 'apache-combined';
  has $!backend;

  use Log::Any::Formatter;
  submethod TWEAK {
    given $!format {
      when 'combined' {
        # Combined apache log format "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""
        $!backend = Log::Any::FormatterBuiltIN.new(
          :format( '\e{h} \e{l} \e{u} [\e{t}] "\e{r}" \e{s} \e{b} "\e{Referer}" \e{User-agent}' )
        );
      }
      when 'common' {
        # Common apache log format "%h %l %u %t \"%r\" %>s %b"
        $!backend = Log::Any::FormatterBuiltIN.new(
          :format(  '\e{h} \e{l} \e{u} [\e{t}] \e{r} \e{s} \e{b}' )
        );
      }
      default {
        $!backend = Log::Any::FormatterBuiltIN.new(
          # Serving GET /test HTTP/1.0 with 200
          :format( 'Serving \e{r} with \e{s}' )
        );
      }
    }
  }

  method format( :$date-time, :$msg!, :$category!, :$severity!, :%extra-fields ) {
    my %data;
    my $request =
      %extra-fields<REQUEST_METHOD> ~ ' '
      ~ %extra-fields<PATH_INFO> // %extra-fields<REQUEST_URI>.split('?')[0] ~ ' '
      ~ %extra-fields<SERVER_PROTOCOL>;

    sub dateTime-to-Str( DateTime:D $date-time ) {
      my @month = <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec>;
      with $date-time {
        sprintf '%02d/%s/%04d:%02d:%02d:%02d %02d',
          .day, @month[.month-1], .year, .hour, .minute, .second, .offset-in-hours * 100
      }
    }

    given $!format {
      when 'combined' {
        %data = Hash.new((
          :h(%extra-fields<SERVER_NAME> // '-' ),
          :l('-'), # RFC 1413 identity of the client, highly unreliable (https://httpd.apache.org/docs/1.3/logs.html)
          :u( %extra-fields<REMOTE_USER> // '-' ), #
          :t( &dateTime-to-Str( DateTime.now ) ),
          :r( $request),
          :s( %extra-fields<HTTP_CODE> // '-'),
          :b( '-' ), # todo, response content size, '-' if null
          :Referer( %extra-fields<HTTP_REFERER> // '-' ),
          :User-agent( %extra-fields<HTTP_USER_AGENT> // '-' ),
        ));
      }
      when 'common' {
        %data = Hash.new((
          :h(%extra-fields<SERVER_NAME> // '-' ),
          :l('-'), # RFC 1413 identity of the client, highly unreliable (https://httpd.apache.org/docs/1.3/logs.html)
          :u( %extra-fields<REMOTE_USER> // '-' ), # todo: user
          :t( dateTime-to-Str( DateTime.now ) ),
          :r($request),
          :s(%extra-fields<HTTP_CODE> // '-'),
          :b( '-' ), # todo, response content size, '-' if null
        ));
      }
      default {
        %data = Hash.new( ( :r($request), :s(%extra-fields<HTTP_CODE>) ) );
      }
    }

    $!backend.format(
      :date-time(''), :msg(''), :category(''), :severity(''),
      :extra-fields( %data )
    );
  }
}
