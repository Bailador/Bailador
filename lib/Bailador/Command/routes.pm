use v6.c;

use Bailador::Command;
use Bailador::Route;

class Bailador::Command::routes does Bailador::Command {

    my sub output-plain($method, @path, *@) {
        my $route = join "", @path;
        $route ~~ s:g/'""'//;
        return if $method == 10;
        put join " ", $method.fmt("%10s"), $route;
    }

    my sub output-tree($method, @path, @is-last) {
        my @indent = map { ' ' x .chars-1 }, @path;
        my @chars = map { ?$_ ?? "   " !! "┃  " }, @is-last;
        @chars[@chars.end] = @is-last[@is-last.end] ?? "┗━━" !! "┣━━";
        my $route = join "", (@indent Z~ @chars), @path[*-1];
        my $meth = $method == 10 ?? "prefix" !! $method;
        put join " ", $meth.fmt("%10s"), $route;
    }

    my sub route-walker(Bailador::Route $r, &process, @path, @is-last) {
        my $path = $r.path-str //
                   do { $r.can('Str').[0].package.perl ne 'Mu' && $r.Str() } //
                   $r.^name;
        @path.push: $path;
        process($r.method, @path, @is-last);
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
