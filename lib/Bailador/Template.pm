use v6.c;

role Bailador::Template {
    has %.template-cache;

    method render($template, @params) { ... }
    method render-file($template-name, @params) {
        unless %.template-cache{$template-name}:exists {
            my $content = slurp($template-name);
            %.template-cache{$template-name} = $content;
        }
        self.render(%.template-cache{$template-name}, @params);
    }
}
