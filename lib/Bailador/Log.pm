use v6.c;

unit module Bailador::Log;

use Bailador::Configuration;
use Bailador::Log::Formatter;
use Bailador::Log::Adapter;

use Log::Any;
use URI;

sub init( :$app ) is export {
  my $config = $app.config();
  my @filter    = $config.log-filter;
  my $formatter = Bailador::Log::Formatter.new(
      format   => $config.log-format,
      colorize => $config.terminal-color,
      colors   => {
          trace     =>  $config.terminal-color-trace,
          debug     =>  $config.terminal-color-debug,
          info      =>  $config.terminal-color-info,
          notice    =>  $config.terminal-color-notice,
          warning   =>  $config.terminal-color-warning,
          error     =>  $config.terminal-color-error,
          critical  =>  $config.terminal-color-critical,
          alert     =>  $config.terminal-color-alert,
          emergency =>  $config.terminal-color-emergency,
      },
  );
  # https://github.com/jsimonet/log-any/issues/1
  # black magic to increase the logging speed
  Log::Any.add( Log::Any::Pipeline.new(), :overwrite );

  # Configure logs
  for $config.logs {
    my $log-output = $_.key;
    my $log-config = $_.value;

    my $log-output-uri = URI.new( $log-output );
    my $adapter;
    my $colorize = False; # Set to config.terminal-color value if output is a terminal
    given $log-output-uri.scheme {
      when 'terminal' {
        given $log-output-uri.path {
          when 'stdout' {
            use Log::Any::Adapter::Stdout;
            $adapter = Log::Any::Adapter::Stdout.new;
          }
          when 'stderr' {
            use Log::Any::Adapter::Stderr;
            $adapter = Log::Any::Adapter::Stderr.new;
          }
        }
        $colorize = $config.terminal-color;
      }
      when 'file' {
        use Log::Any::Adapter::File;
        $adapter = Log::Any::Adapter::File.new( :path($log-output-uri.path) );
      }
      when 'p6w' {
        given $log-output-uri.path {
          when 'errors' {
            # my $app = app();
            $adapter = $app.log-adapter;
          }
        }
      }
      default { die "Invalid output ($log-output)." }
    }
    my $format = $log-config{'format'} // '';

    # Check filters
    my @filters;
    if $log-config{'category'} -> $category {
      @filters.push( 'category' => $category );
    }

    if $log-config{'severity'} -> $severity {
      @filters.push( 'severity' => $severity );
    }

    Log::Any.add( $adapter,
      :formatter(
        Bailador::Log::Formatter.new(
          format => $format,
          colorize => $colorize,
          colors   => {
            trace     =>  $config.terminal-color-trace,
            debug     =>  $config.terminal-color-debug,
            info      =>  $config.terminal-color-info,
            notice    =>  $config.terminal-color-notice,
            warning   =>  $config.terminal-color-warning,
            error     =>  $config.terminal-color-error,
            critical  =>  $config.terminal-color-critical,
            alert     =>  $config.terminal-color-alert,
            emergency =>  $config.terminal-color-emergency,
          }
        )
      ),
      :filter( @filters ),
      :continue-on-match,
    );
  }

}
