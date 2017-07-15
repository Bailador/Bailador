use v6.c;

use Bailador::Command;
use Bailador::Route;

class Bailador::Command::routes does Bailador::Command {

    my sub output-plain($shortname, $method, @path, *@) {
        put join " ", $shortname.fmt("%10s"), $method.fmt("%10s"), join " -> ", @path;
    }

    my sub output-tree($shortname, $method, @path, @is-last) {
        my @indent = map {' ' x $_.chars - 1}, @path;
        my @chars  = map { ?$_ ?? "   " !! "┃  " }, @is-last;
        @chars[@chars.end] = @is-last[@is-last.end] ?? "┗━━" !! "┣━━" if +@is-last;
        my $route = join "", (@indent Z~ @chars), @path[ * - 1 ];
        put join " ", $shortname.fmt("%10s"), $method.fmt("%10s"), $route;
    }

    my sub route-walker(Bailador::Route $r, &process, @path, @is-last) {
        @path.push: $r.route-spec;
        process($r.^shortname, $r.method-spec, @path, @is-last);
        if $r.routes > 0 {
            for $r.routes.list.kv -> $i, $v {
                @is-last.push: $i == +$r.routes.end;
                route-walker($v, &process, @path, @is-last);
                @is-last.pop;
            }
        }
        @path.pop;
    }

    method run(:$app) {
        my $config = $app.config;
        my &output-routine = $config.routes-output eq 'tree' ?? &output-tree !! &output-plain;
        route-walker($_, &output-routine, [], []) for $app.routes;
    }
}
