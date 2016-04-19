use URI::Escape;

class Bailador::Response {
    has $.code     is rw;
    has %.headers  is rw;
    has @.content  is rw;
    has @.cookies  is rw;

    method psgi {
        my @headers = %.headers.list;
        for @.cookies { @headers.push("Set-Cookie" => $_) }
        [ $.code, [ @headers ], |@.content ]
    }

    method cookie(Str $name, Str $value, Str :$domain, Str :$path,
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
    self.cookies.push: uri_escape($name) ~ "=$c";
}

}
