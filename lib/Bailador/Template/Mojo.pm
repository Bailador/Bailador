use Bailador::Template;

unit class Bailador::Template::Mojo does Bailador::Template;
use Template::Mojo;

has $!engine = Template::Mojo;

method render($template, @params) {
    $!engine.new($template).render(|@params)
}
