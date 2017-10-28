use v6.c;

use Test;

plan 3;

# Test Bailador::Log::Adapter
subtest {
  plan 3;

  use-ok 'Bailador::Log::Adapter';
  use Bailador::Log::Adapter;

  # Used to test io-handle.say method
  class MyStdout {
    has @.said;
    multi method say( Str $s ) {
      @!said.push( $s );
    }
  }

  my $a = Bailador::Log::Adapter.new;
  my $stdout = MyStdout.new();
  $a.io-handle = $stdout;

  $a.handle( 'formatted log line' );

  is $stdout.said.elems, 1, 'One log line logged.';
  is $stdout.said, [ 'formatted log line' ], 'Correctly handled logged line.';

}, 'Test Bailador::Log::Adapter.';

# Test Bailador::Log::Formatter
subtest {
  plan 11;

  use-ok 'Bailador::Log::Formatter';
  use Bailador::Log::Formatter;

  {
    my $format-attribute = Bailador::Log::Formatter.^attributes.grep( *.name eq '$!format' )[0];

    my $f = Bailador::Log::Formatter.new( :template-format<common> );
    is $format-attribute.get_value( $f ), '\e{h} \e{l} \e{u} [\e{t}] \e{r} \e{s} \e{b}', 'common format';
    like
      $f.format(
        :date-time( DateTime.new('2017-11-28T15:08:00') ), :msg('mm'), :category('testing format'), :severity('debug'),
        :extra-fields( Hash.new( (SERVER_NAME => 'localhost', REMOTE_USER => 'me', REQUEST_METHOD => 'GET', PATH_INFO => '/path', SERVER_PROTOCOL => 'http', HTTP_CODE => 200, ) ) ),
      ),
      / 'localhost - me [' \d ** 2 \/ \w ** 3 \/ \d ** 4 [':' \d\d] ** 3 \s \d ** 3 '] GET /path http 200' /,
      'common formatted value match';

    # Test
    $f = Bailador::Log::Formatter.new( :template-format<combined> );
    is $format-attribute.get_value( $f ), '\e{h} \e{l} \e{u} [\e{t}] "\e{r}" \e{s} \e{b} "\e{Referer}" \e{User-agent}', 'combined format';
    like
      $f.format(
        :date-time( DateTime.new('2017-11-28T15:08:00') ), :msg('mm'), :category('testing format'), :severity('debug'),
        :extra-fields( Hash.new( (:SERVER_NAME<localhost>, :REMOTE_USER<me>, :REQUEST_METHOD<GET>, :PATH_INFO</path>, :SERVER_PROTOCOL<http>, :HTTP_CODE(200), :b(123), :HTTP_REFERER('Fake ref'), :HTTP_USER_AGENT('fake-ua') ) ) ),
      ),
      / 'localhost - me [' \d ** 2 \/ \w ** 3 \/ \d ** 4 [':' \d\d] ** 3 \s \d ** 3 '] "GET /path http" 200 - "Fake ref" fake-ua' /,
      'combined formatted log match';

    # Test simple format
    $f = Bailador::Log::Formatter.new( :template-format<simple> );
    is $format-attribute.get_value( $f ), '[\e{t}] [\e{l}] [pid \e{P}] \e{F}: \e{E}: [client \e{a}] "\e{M}"', 'simple format';
    like
      $f.format(
        :date-time( DateTime.new('2017-11-28T15:08:00') ), :msg('mm'), :category('testing format'), :severity('debug'),
        :extra-fields( Hash.new( (:pid('1456'), :file-and-line('file.txt line 42'), :client-ip('10.0.0.1') ) ) ),
      ),
      / '[' \d ** 2 \/ \w ** 3 \/ \d ** 4 [':' \d\d] ** 3 \s \d ** 3 ']' .*/,
      'simple formatted log match';

    # Default logging format is just the message
    $f = Bailador::Log::Formatter.new;
    is $format-attribute.get_value( $f ), '\m', 'Default logging format is \m';

    dies-ok { Bailador::Log::Formatter.new( :template-format<mpm> ) },  'Template-format "mpm" not yet implemented.';
    dies-ok { Bailador::Log::Formatter.new( :template-format<plop> ) }, 'Template-format "plop" unknown.';

    $f = Bailador::Log::Formatter.new( :format('my format') );
    is $format-attribute.get_value( $f ), 'my format', 'User specific format';
  }

}, 'Bailador::Log::Formatter';

# Test Bailador::Log::init() method
todo 'Bailador::Log';
subtest {
  plan 1;

  use-ok 'Bailador::Log';
  use Bailador::Log;

  # Test URI destinations
  my @uris-ok = (
  'file:///path/to/log.log',
  'console://stderr',
  'console://stdout',
  'p6w.errors://',
  );

  my @uris-nok = (
  'file', # No file specified
  'unknown://',
  'console://nop',
  );

  # Test filters

  # Test template-match
  # Test template-format


  # Test simple config
  my @log-config = [
  ];
}, 'Test Bailador::Log::init() method.';
