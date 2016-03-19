use Bailador::App;
use Bailador::Request;
use Bailador::Response;
use Bailador::Context;
use HTTP::Easy::PSGI;
use URI::Escape;

unit module Bailador;

my $app = Bailador::App.current;

our sub import {
    my $file = callframe(1).file;
    my $slash = $file.rindex('/');
    if $slash {
        $app.location = $file.substr(0, $file.rindex('/'));
    } else {
        $app.location = '.';
    }
}

sub route_to_regex($route) {
    $route.split('/').map({
        my $r = $_;
        if $_.substr(0, 1) eq ':' {
            $r = q{(<-[\/\.]>+)};
        }
        $r
    }).join("'/'");
}

multi parse_route(Str $route) {
    my $r = route_to_regex($route);
    return "/ ^ $r \$ /".EVAL;
}

multi parse_route($route) {
    # do nothing
    $route
}

sub get(Pair $x) is export {
    my $p = parse_route($x.key) => $x.value;
    $app.add_route: 'GET', $p;
    return $x;
}

sub post(Pair $x) is export {
    my $p = parse_route($x.key) => $x.value;
    $app.add_route: 'POST', $p;
    return $x;
}

sub put(Pair $x) is export {
    my $p = parse_route($x.key) => $x.value;
    $app.add_route: 'PUT', $p;
    return $x;
}

sub delete(Pair $x) is export {
    my $p = parse_route($x.key) => $x.value;
    $app.add_route: 'DELETE', $p;
    return $x;
}

sub request is export { $app.context.request }

sub content_type(Str $type) is export {
    $app.response.headers<Content-Type> = $type;
}

sub header(Str $name, Cool $value) is export {
    $app.response.headers{$name} = ~$value;
}

sub cookie(Str $name, Str $value, Str :$domain, Str :$path,
        DateTime :$expires, Bool :$http-only; Bool :$secure) is export {
    my $c = uri_escape($value);
    if $path    { $c ~= "; Path=$path" }
    if $domain  { $c ~= "; Domain=$domain" }
    if $expires {
        my $dt = $expires.utc;
        my $wdy = do given $dt.day-of-week {
            when 1 { <Mon> }
            when 2 { <Tue> }
            when 3 { <Wed> }
            when 4 { <Thu> }
            when 5 { <Fri> }
            when 6 { <Sat> }
            when 7 { <Sun> }
        }
        my $day = $dt.day-of-month.fmt('%02d');
        my $mon = do given $dt.month {
            when 1  { <Jan> }
            when 2  { <Feb> }
            when 3  { <Mar> }
            when 4  { <Apr> }
            when 5  { <May> }
            when 6  { <Jun> }
            when 7  { <Jul> }
            when 8  { <Aug> }
            when 9  { <Sep> }
            when 10 { <Oct> }
            when 11 { <Nov> }
            when 12 { <Dec> }
        }
        my $year = $dt.year.fmt('%04d');
        my $time = sprintf('%02d:%02d:%02d', $dt.hour, $dt.minute, $dt.second);
        $c ~= "; Expires=$wdy, $day $mon $year $time GMT";
    }
    if $secure    { $c ~= "; Secure" }
    if $http-only { $c ~= "; HttpOnly" }
    $app.response.cookies.push: uri_escape($name) ~ "=$c";
}

sub status(Int $code) is export {
    $app.response.code = $code;
}

sub template(Str $tmpl, *@params) is export {
    $app.template($tmpl, @params);
}

our sub dispatch_request(Bailador::Request $r) {
    return dispatch($r.env);
}

sub dispatch($env) {
    $app.context.env = $env;

    my ($r, $match) = $app.find_route($env);

    if $r {
        try {
            status 200;
            if $match {
                $app.response.content = $r.value.(|$match.list);
            } else {
                $app.response.content = $r.value.();
            }
            CATCH {
                default {
                    my $env = $app.request.env;
                    my $err = $env<p6sgi.version>:exists ?? $env<p6sgi.errors> !! $env<p6sgi.errors>;
                    $err.say(.gist);
                    status 500;
                    if 'views/500.html'.IO ~~ :e {
                      $app.response.content = slurp('views/500.html');
                    } else {
                      content_type 'text/plain';
                      $app.response.content = 'Internal Server Error';
                    }
                }
            }
        }
    }

    return $app.response;
}

our sub dispatch-psgi($env) {
    return dispatch($env).psgi;
}

sub baile($port = 3000) is export {
    given HTTP::Easy::PSGI.new(:host<0.0.0.0>, :$port) {
        .app(&dispatch-psgi);
        say "Entering the development dance floor: http://0.0.0.0:$port";
        .run;
    }
}
