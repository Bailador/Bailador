use v6;

use Bailador::Command;

class Bailador::Command::routes does Bailador::Command {
    sub print-routes($prefix,@routes) {
        for @routes -> $r {
            # Try to combine the prefix and .path-str
            # If we don't have a .path-str, call .Str unless it was inherited from Mu
            # otherwise just output the name of the Route class
            my $path = $prefix ~ ($r.path-str //
                                  do { $r.can('Str').[0].package.perl ne 'Mu' && $r.Str() } //
                                  $r.^name);
            if $r.routes > 0 { 
                print-routes($path, $r.routes);
            } else {
                # because we've concatenated .perl strings, 
                # get rid of the doubled "" in the middle
                $path ~~ s:g/'""'//;    
                for $r.method.list -> $method {
                    put join " ", $method.fmt("%10s"), $path;
                }
            }
        }
    }

    method run(:$app) {
        print-routes('',$app.routes);
    }
}
