use v6;

use Bailador::Context;
use Bailador::Route;
use Bailador::Template::Mojo;
use Bailador::Sessions;
use Bailador::Sessions::Config;
use Bailador::Exceptions;
use Bailador::ContentTypes;

class Bailador::App is Bailador::Route {
    has Str $.location is rw = '.';
    has Bool $.debug is rw = False;
    has Bailador::ContentTypes $.content-types = Bailador::ContentTypes.new;
    has Bailador::Context  $.context  = Bailador::Context.new;
    has Bailador::Template $.renderer is rw = Bailador::Template::Mojo.new;
    has Bailador::Sessions::Config $.sessions-config = Bailador::Sessions::Config.new;
    has Bailador::Sessions $!sessions;

    my $error-template = q{
% my (%h) = @_;

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=yes">
  <title>Error in Bailador</title>
<style>
td {
   border: solid 1px;
}
#exception {
   background-color: #f4b541;
}
</style>
</head>
<body>
  <h1>An error has occured</h1>
  In the future this will be a nice error page. For now we try to make it at least informative.
  You see this detailed error message because Bailador is in debug-mode. In production mode a 500 error will be sent to the client that you can customize.

  <h2>Exception</h2>
  <pre id="exception">
    <%= %h<exception> %>
  </pre>

  <h2>Request</h2>
  <table>
% for <
%       address
%       content_length
%       content_type
%       method
%       path
%       port
%       protocol
%       referer
%       remote_host
%       request_uri
%       scheme
%       script_name
%       secure
%       server
%       uri
%       user
%       user_agent
%     > -> $f {
          <tr><td><%= $f %></td><td><%= %h<request>."$f"() %></td></tr>
% }
  </table>

<h2>Perl</h2>
<table>
  <tr><td>$*PROGRAM-NAME</td><td><%= %h<PROGRAM-NAME> %></td></tr>
  <tr><td>$*EXECUTABLE</td><td><%= %h<EXECUTABLE> %></td></tr>
</table>

<h2>ENV</h2>
   <table>
% for %*ENV -> $p {
     <tr><td><%= $p.key %></td><td><%= $p.value %></td></tr>
% }
   </table>

</body>
</html>
};

    method request  { $.context.request  }
    method response { $.context.response }
    method template(Str $tmpl, *@params, *%params) {
        $!renderer.render("$.location/views/$tmpl", @params, |%params);
    }

    multi method render($result) {
        if $result ~~ IO::Path {
            my $type = $.content-types.detect-type($result);
            self.render: content => $result.slurp(:bin), :$type;
        }
        else {
            self.render(content => $result);
        }
    }

    multi method render(Int :$status = 200, Str :$type, :$content!) {
        $.context.autorender = False;
        self.response.code = $status;
        self.response.headers<Content-Type> = $type if $type;
        self.response.content = $content;
    }

    multi method redirect(Str $location, Int :$code = 302) {
        $.context.autorender = False;
        self.response.code = $code;
        self.response.headers<Location> = $location;
    }

    method !sessions() {
        unless $!sessions.defined {
            $!sessions = Bailador::Sessions.new(:$.sessions-config);
        }
        return $!sessions;
    }

    method session() {
        self!sessions.load(self.request);
    }

    method session-delete() {
        self!sessions.delete-session(self.request);
    }

    method done-rendering() {
        # store session according to session engine
        self!sessions.store(self.response, self.request.env);
    }

    method get-psgi-app {
        # quotes from https://github.com/zostay/P6SGI
        # draft 0.7
        # * A P6SGI application is a Perl 6 routine that expects to receive an environment from an application server and returns a response each time it is called by the server.
        # * An application MUST return a Promise
        # * The message payload MUST be a sane Supply or an object that coerces into a sane Supply.
        return sub (%env) {
            start {
                self.dispatch(%env).psgi;
            }
        }
    }

    method dispatch($env) {
        self.context.env = $env;
        try {
            my $method = $env<REQUEST_METHOD>;
            my $uri    = $env<PATH_INFO>;
            my $result = self.recurse-on-routes($method, $uri);

            if $.context.autorender {
                if $result.defined {
                    self.render: $result;
                }
                else {
                    die X::Bailador::ControllerReturnedNoResult.new(:$method, :$uri);
                }
            }

            LEAVE {
                self.done-rendering();
            }

            CATCH {
                when X::Bailador::ControllerReturnedNoResult {
                    self.render(content => Any);
                }
                when X::Bailador::NoRouteFound {
                    my $err-page;
                    if $!location.defined {
                        $err-page = "$!location/views/404.xx".IO.e ?? self.template("404.xx", []) !! 'Not found';
                    } else {
                        $err-page = 'Not found';
                    }
                    self.render(status => 404, type => 'text/html, charset=utf-8', content => $err-page);
                }
                default {
                    if ($env<p6w.errors>:exists) {
                        my $err = $env<p6w.errors>;
                        $err.say(.gist);
                    }
                    else {
                        note .gist;
                    }

                    my $err-page;
                    if $!debug {
                        my %h = (exception => .gist, request => self.request());
                        $err-page = $!renderer.render-string($error-template, %h);
                    } elsif $!location.defined {
                        $err-page = "$!location/views/500.xx".IO.e ?? self.template("500.xx", []) !! 'Internal Server Error';
                    } else {
                        $err-page = 'Internal Server Error';
                    }
                    self.render(status => 500, type => 'text/html, charset=utf-8', content => $err-page);
                }
            }
        }

        return self.response;
    }

    method curry(Str:D $method, *@args) {
        die "Method $method not found on class " ~ self.WHAT.gist unless self.^method_table{$method}:exists;
        return self.^method_table{$method}.assuming(self, |@args);
    }
}
