use v6.c;

use Bailador::Command;
use Bailador::Route;

class Bailador::Command::routes does Bailador::Command {

    my sub output-plain($shortname, $method, $path, *@) {
        put join " ", $shortname.fmt("%10s"), $method.fmt("%10s"), $path;
    }

    my sub output-tree($shortname, $method, $path, @indent, @is-last) {
        my @chars = map { ?$_ ?? "   " !! "┃  " }, @is-last;
        @chars[@chars.end] = @is-last[@is-last.end] ?? "┗━━" !! "┣━━" if +@is-last;
        my $route = join "", (@indent Z~ @chars), $path;
        put join " ", $shortname.fmt("%10s"), $method.fmt("%10s"), $route;
    }

    my sub route-walker(Bailador::Route $r, &process, @indent, @is-last) {
        @indent.push: ' ' x $r.route-spec.chars - 1;
        process($r.^shortname, $r.method-spec, $r.route-spec, @indent, @is-last);
        if $r.routes > 0 {
            for $r.routes.list.kv -> $i, $v {
                @is-last.push: $i == +$r.routes.end;
                route-walker($v, &process, @indent, @is-last);
                @is-last.pop;
            }
        }
        @indent.pop;
    }

    method run(:$app) {
        my $config = $app.config;
        my &output-routine = $config.routes-output eq 'tree' ?? &output-tree !! &output-plain;
        route-walker($_, &output-routine, [], []) for $app.routes;
    }
}
