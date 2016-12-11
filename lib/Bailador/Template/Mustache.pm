use v6.c;
use Bailador::Template;

class Bailador::Template::Mustache does Bailador::Template {
    use Template::Mustache;

    has $.engine = Template::Mustache.new;

    method render($template, @params) {
        $!engine.render($template, |@params);
    }
}
