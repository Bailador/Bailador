### Status
[![Build Status](https://travis-ci.org/tadzik/Bailador.png)](https://travis-ci.org/tadzik/Bailador)

A light-weight route-based web application framework for Perl 6
==============================================

    use Bailador;
    
    # simple cases
    get '/' => sub {
        "hello world"
    }
    
    baile;

For more examples see the examples/ folder.

Exported subs
================

Subroutines for your Application
--------------------------------

### `get(Pair $x)`
### `post(Pair $x)`
### `put(Pair $x)`
### `delete(Pair $x)`

Addes A Route for get, post, put or delete requests.

### `renderer(Bailador::Template $renderer)`

Sets the Renderer that's being used to render your templates. See the Template section for more details.

### `baile()`

Lets enter the dance floor. ¡Olé!

Subroutines that sould only be used inside the Code block of a Route
-------------------------------------------------------------------

### `content_type(Str $type)`

Sets the Content Type for the response to $type.

### `request()`

Gets current the Request.

### `header(Str $name, Cool $value)`

Adds a Header to the Repsonse.

### `cookie(Str $name, Str $value, Str :$domain, Str :$path, DateTime :$expires, Bool :$http-only; Bool :$secure)`

Adds a Cookie to the response.

### `status(Int $code)`

Sets the status code of a response.

### `template(Str $template-name, *@params)`

Calls the template which is a file in the views folder. For more details see the Template section. Should only be used within the code block of a route.

Routing
=======

Routes are easily created with a subroutine that is called like the HTTP method you want to use followed by a code block or anything that is "Callable".
The return value of the code block or Callable is content of the response that's been sent back to the browser. If you want to send cookies or headers use

    cookie()
    header()
    
as described in the methods above.

Templates
=========

Currently there are 2 different engines supported out of the box: Template::Mojo and Template::Mustache.
Where Template::Mojo is the default engine but if you want to switch to Template::Mustache you just call

    renderer(Bailador::Template::Mustache.new);

It is possible to user other template engines as well.
Therefore you need to create a class that implements the role Bailador::Template. Its basically just required to implement the render method.

The template files should be placed in a folder named "views" which is located in the same directory as your application.pl file. When you call the subroutine

    template 'template.tt', $name, $something;
    
the template (or in other words the file views/template.tt) gets invoked "as a subroutine" and the @params get passed. This is a example of a template file with Template::Mojo:

    % my ($name, $something) = @_;
    <html ... codes goes here ...>
        <h1><% $name %></h1>
    <html>

Bailador-based applications
===========================
* https://github.com/szabgab/Perl6-Maven serving http://perl6maven.com/
* https://github.com/perl6/cpandatesters.perl6.org/ used to serve http://testers.p6c.org/ but currently not in use


Articles about Bailador
========================
http://perl6maven.com/bailador
