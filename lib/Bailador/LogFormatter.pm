use v6.c;

# Log::Any v 0.9.4 introduces extra-fields.
use Log::Any::Formatter:ver('0.9.4');

use Terminal::ANSIColor;

class Bailador::LogFormatter is Log::Any::Formatter {
  has $.format = '';
  has $!backend;
  has %.colors;
  has $.log-any-formatter;
  has $.colorize;

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
      when 'simple' {
        # "[%t] [%l] [pid %P] %F: %E: [client %a] %M"
        $!backend = Log::Any::FormatterBuiltIN.new(
          :format(  '[\e{t}] [\e{l}] [pid \e{P}] \e{F}: \e{E}: [client \e{a}] "\e{M}"' )
        );
      }
      when 'mpm' {
        #  [Fri Sep 09 10:42:29.902022 2011] [core:error] [pid 35708:tid 4328636416] [client 72.15.99.187] File does not exist: /usr/local/apache2/htdocs/favicon.ico
        # "[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i"
        ...
      }
      default {
        $!backend = Log::Any::FormatterBuiltIN.new(
          # Serving GET /test HTTP/1.0 with 200
          :format( '\m' )
        );
      }
    }
  }

  method format( :$date-time, :$msg!, :$category!, :$severity!, :%extra-fields ) {
    my %data;
    my $query-uri = %extra-fields<REQUEST_URI>
      ?? %extra-fields<REQUEST_URI>.split('?')[0]
      !! '';
    my $request =
        ( %extra-fields<REQUEST_METHOD> || '' ) ~ ' '
      ~ ( %extra-fields<PATH_INFO> || $query-uri ) ~ ' '
      ~ ( %extra-fields<SERVER_PROTOCOL> || '' );

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
      when 'simple' {
        # "[%t] [%l] [pid %P] %F: %E: [client %a] %M"
        %data = Hash.new((
          :t( dateTime-to-Str( DateTime.now ) ),
          :l( $severity ),
          :P( %extra-fields<pid> ),
          :F( %extra-fields<file-and-line>),
          :E( '-' ), # APR/OS error status code and string
          :a( %extra-fields<client-ip> ),
          :M( $msg )
        ));
      }
      when 'mpm' {
        #  [Fri Sep 09 10:42:29.902022 2011] [core:error] [pid 35708:tid 4328636416] [client 72.15.99.187] File does not exist: /usr/local/apache2/htdocs/favicon.ico
        # "[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i"
        ...
      }
      default {
        %data = Hash.new( ( :r($request), :s(%extra-fields<HTTP_CODE>) ) );
      }
    }

    my $log-formatted = $!backend.format(
      :$date-time, :$msg, :$category, :$severity,
      :extra-fields( %data )
    );

    # Colorize output
    my $override = %extra-fields<color>;
    my $color    = $override || %.colors{ $severity };
    return ($.colorize && $color) ?? colored($log-formatted, $color) !! $log-formatted;
  }
}
