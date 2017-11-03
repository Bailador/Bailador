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
subtest {
  # plan 1;

  use-ok 'Bailador::Log';
  use Bailador::Log;

  my class IO::Capture is IO::Handle {
    has @.output;

    method print-nl { self.print($.nl-out); }
    method print (*@what) {
      @!output.push( @what.join('') );
    }

    method say (*@what) {
      @!output.push( @what.join('') );
    }
  }

  # Override STDOUT and STDERR to capture output
  # If a message like "No exception handler located for catch" is shown,
  # it probably means that an error occured which couldn't be printed to terminal
  my $OUT-capture = $*OUT;
  $*OUT           = IO::Capture.new;
  my $ERR-capture = $*ERR;
  $*ERR           = IO::Capture.new;

  # Create a fake application
  use Bailador::App;
  my $app = Bailador::App.new(
   config => Bailador::Configuration.new( logs => () ),
  );
  # Add a route for test
  use Bailador::Route::Simple;
  $app.add_route( Bailador::Route::Simple.new( :method('GET'), :url-matcher<path>, :code( {'hello test'} ) ) );

  use Log::Any::Adapter::Stderr;
  # Todo: generate a random and temporary file (/tmp/bailador-nrsite/log.log)
  init( config => Bailador::Configuration.new( logs => ('file:tmp.log' => {}) ), p6w-adapter => Log::Any::Adapter::Stderr.new );
  $app.dispatch( {:REQUEST_METHOD<GET>, :PATH_INFO<path>, :REQUEST_URI</path>} );

  # Get back to standard output
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);
  is $OUT-capture.output.elems, 0, 'Nothing get logged to STDOUT';
  is $ERR-capture.output.elems, 0, 'Nothing get logged to STDERR';
  todo 'Test tmp.log file content';
  flunk 'NYI file content test';

  # Capture output
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);
  # Log everything to STDOUT
  init( config => Bailador::Configuration.new( logs => ('terminal:stdout' => {}) ), p6w-adapter => Log::Any::Adapter::Stderr.new );
  $app.dispatch( {:REQUEST_METHOD<GET>, :PATH_INFO<path>, :REQUEST_URI</path>} );

  # Get back standard output
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);

  is $OUT-capture.output.elems, 1, 'One line get logged to STDOUT';
  like $OUT-capture.output[0], /^ 'Serving GET path with 200 in ' .* /;
  is $ERR-capture.output.elems, 0, 'Nothing get logged to STDERR';

  # Log everything to STDERR
  # Capture output
  $OUT-capture.output = [];
  $ERR-capture.output = [];
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);
  init( config => Bailador::Configuration.new( logs => ('terminal:stderr' => {}) ), p6w-adapter => Log::Any::Adapter::Stderr.new );
  $app.dispatch( {:REQUEST_METHOD<GET>, :PATH_INFO<path>, :REQUEST_URI</path>} );
  # Get back standard output
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);

  is $ERR-capture.output.elems, 1, 'One line get logged to STDERR';
  like $ERR-capture.output[0], /^ 'Serving GET path with 200 in ' .* /;
  is $OUT-capture.output.elems, 0, 'Nothing get logged to STDOUT';

  # Test logging to p6w.errors, basically the same thing as the STDERR
  # Will use the :p6w-adapter parameter to discover where to log (here STDERR)
  # Capture output
  $OUT-capture.output = [];
  $ERR-capture.output = [];
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);
  init( config => Bailador::Configuration.new( logs => ( 'p6w:errors' => {} ), ), p6w-adapter => Log::Any::Adapter::Stderr.new );
  $app.dispatch( {:REQUEST_METHOD<GET>, :PATH_INFO<path>, :REQUEST_URI</path>} );
  # Get back standard output
  ($*OUT, $OUT-capture) = ($OUT-capture, $*OUT);
  ($*ERR, $ERR-capture) = ($ERR-capture, $*ERR);

  is $ERR-capture.output.elems, 1, 'One line get logged to STDERR';
  like $ERR-capture.output[0], /^ 'Serving GET path with 200 in ' .* /;
  is $OUT-capture.output.elems, 0, 'Nothing get logged to STDOUT';

  # Test filters

  # Test template-match
  # Test template-format


  # Test simple config
  my @log-config = [
  ];
  done-testing;
}, 'Test Bailador::Log::init() method.';
