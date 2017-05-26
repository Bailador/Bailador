use v6.c;
use Bailador::Template;
use Template::Mojo;

class Bailador::Template::Mojo does Bailador::Template {
    has %.template-cache;
    has $!engine = Template::Mojo;

    method render(Str $template-name, @params) {
        my $engine = self!get-engine($template-name);
        $engine.render(|@params)
    }

    method render-string(Str $template-content, %params) {
        my $engine = Template::Mojo.new($template-content);
        return $engine.render(%params);
    }

    method !get-engine(Str $template-name) {
        unless %.template-cache{$template-name}:exists {
            %.template-cache{$template-name} = Template::Mojo.new($template-name.IO.slurp);
        }
        return %.template-cache{$template-name};
    }
}
