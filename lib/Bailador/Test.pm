use Test;
use Bailador;
use Bailador::Request;

module Bailador::Test;

sub route-exists($meth, $path, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    ok Bailador::App.current.find_route($req), $desc;
}

sub route-doesnt-exist($meth, $path, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    ok !Bailador::App.current.find_route($req), $desc;
}

sub response-status-is($meth, $path, $status, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    my $resp = Bailador::dispatch_request($req);
    is $resp.code, $status, $desc;
}

sub response-status-isnt($meth, $path, $status, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    my $resp = Bailador::dispatch_request($req);
    isnt $resp.code, $status, $desc;
}

sub response-content-is($meth, $path, $cont, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    my $resp = Bailador::dispatch_request($req);
    is ~$resp.content, $cont, $desc;
}

sub response-content-isnt($meth, $path, $cont, $desc = '') is export {
    my $req = Bailador::Request.new_for_request($meth, $path);
    my $resp = Bailador::dispatch_request($req);
    isnt ~$resp.content, $cont, $desc;
}

sub response-content-is-deeply($meth, $path, $cont, $desc) is export { ... }
sub response-content-like($meth, $path, $cont, $desc) is export { ... }
sub response-content-unlike($meth, $path, $cont, $desc) is export { ... }

sub response-headers-are-deeply($meth, $path, $cont, $desc) is export { ... }
sub response-headers-include($meth, $path, $cont, $desc) is export { ... }

sub bailador-response($meth, $path, *%opts) is export { ... }

sub read-logs is export { ... }
