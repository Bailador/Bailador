use v6.c;

role Bailador::Hookable {

    has %!hooks;

    submethod TWEAK {
        for self.supported-hooks -> $name {
            %!hooks{$name} = [];
        }
    }

    method supported-hooks() { ... }

    method add-hook(Pair $hook) {
        my $name = $hook.key;
        my $code = $hook.value;

        warn "Unsupported hook '$name'"
        unless %!hooks{$name}:exists;

        %!hooks{$name}.push($code);
    }

    method invoke-hooks(Str $name) {
        for %!hooks{$name} -> &hook-code {
            hook-code();
        }
    }
}
