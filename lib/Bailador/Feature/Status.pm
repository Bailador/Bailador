use v6.c;

use Bailador;

app.config.report = True;

get '/bailador' => sub {
    my Str $mode = app.config.mode;
    my Int $requests-number = app.requests-number;

    my %status =
        running => 'ok',
        mode => $mode,
        requests => $requests-number;

    return to-json %status;
}
