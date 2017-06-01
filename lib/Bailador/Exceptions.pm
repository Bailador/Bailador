use v6;

class X::Bailador::NoRouteFound is Exception {
    method message() {
        "Did not find a route that matches the request";
    }
}

class X::Bailador::ControllerReturnedNoResult is Exception {
    has Str $.method;
    has Str $.uri;
    method message() {
        "Controller did not return a defined value for HTTP method: $.method on URI: $.uri";
    }
}
