# Bailador

[![Build Status](https://travis-ci.org/ufobat/Bailador.png)](https://travis-ci.org/ufobat/Bailador) [![Build status](https://ci.appveyor.com/api/projects/status/github/ufobat/Bailador?svg=true)](https://ci.appveyor.com/project/ufobat/Bailador/branch/master)

A light-weight route-based web application framework for Perl 6

# TABLE OF CONTENTS
- [Example](#example)
- [How to Write Web Apps](#how-to-write-web-apps)
    - [Classical Approach](#classical-approach)
        - [Mixing both Approaches](#mixing-both-approaches)
        - [Subroutines for your Application](#subroutines-for-your-application)
            - [`app(Bailador::App $app)`](#appbailadorapp-app)
            - [`get(Pair $x)`](#getpair-x)
            - [`post(Pair $x)`](#postpair-x)
            - [`put(Pair $x)`](#putpair-x)
            - [`delete(Pair $x)`](#deletepair-x)
            - [`renderer(Bailador::Template $renderer)`](#rendererbailadortemplate-renderer)
            - [`sessions-config()`](#sessions-config)
            - [`baile()`](#baile)
            - [`get-psgi-app`](#get-psgi-app)
        - [Subroutines that sould only be used inside the Code block of a Route](#subroutines-that-sould-only-be-used-inside-the-code-block-of-a-route)
            - [`content_type(Str $type)`](#content_typestr-type)
            - [`request()`](#request)
            - [`header(Str $name, Cool $value)`](#headerstr-name-cool-value)
            - [`cookie(Str $name, Str $value, Str :$domain, Str :$path, DateTime :$expires, Bool :$http-only; Bool :$secure)`](#cookiestr-name-str-value-str-domain-str-path-datetime-expires-bool-http-only-bool-secure)
            - [`status(Int $code)`](#statusint-code)
            - [`template(Str $template-name, *@params)`](#templatestr-template-name-params)
            - [`session()`](#session)
- [Web Applications via Inheriting from `Bailador::App`](#web-applications-via-inheriting-from-bailadorapp)
    - [Nested Routes](#nested-routes)
    - [Auto Rendering](#auto-rendering)
    - [Return Values of Routes](#return-values-of-routes)
    - [Bailador::Route::StaticFile](#bailadorroutestaticfile)
- [Templates](#templates)
- [Sessions](#sessions)
- [Bailador-based applications](#bailador-based-applications)
- [Articles about Bailador](#articles-about-bailador)
- [License](#license)

## Example

```Perl6
use Bailador;
    
# simple cases
get '/' => sub {
    "hello world"
}
    
baile;
```

For more examples, please see the [examples](examples) folder.

## How to Write Web Apps

Bailador offers two different approaches to write web applications. The first and classical approach is using the subs that are exported that you get when you `use Bailador`. This API is ment to be stable and should not change much.

New features like nested routes and whatever is yet to come are implemented in `Bailador::App` and can be used through the object oriented interface. Your own web application just inherits from `Bailador::App`.

### Mixing both Approaches

When you write your own application, but still want to use the exported subs described in [this](#subroutines-that-sould-only-be-used-inside-the-code-block-of-a-route) section you MUST set your `$app` to be the default app.

```Perl6
use Bailador;
use Bailador::App;

class MyWebApp is Bailador::App { ... }
my $app = MyWebApp.new;

app $app;
```

### Classical Approach

#### Subroutines for your Application

#### `app(Bailador::App $app)`

Sets a Bailador::App to be the default app for all the other exported subs described in [Subroutines that sould only be used inside the Code block of a Route](#subroutines-that-sould-only-be-used-inside-the-code-block-of-a-route).

##### `get(Pair $x)`
##### `post(Pair $x)`
##### `put(Pair $x)`
##### `delete(Pair $x)`

Adds a route for get, post, put or delete requests. The key of the `Pair` is either a `Str` or a `Regex`. If a string is passed it is automatically converted into a regex. The value of the pair must be a `Callable`. Whenever the route matches on the requested URL the callable is invoked with the list of the `Match` as its parameters. The return value of the callable will be autorendered. So it is the content of your response.

##### `renderer(Bailador::Template $renderer)`

Sets the Renderer that's being used to render your templates. See the Template section for more details.

##### `sessions-config()`

Returns the Sessions-config. You can influence how sessions work. See the Sessions section for details.

##### `baile()`

Lets enter the dance floor. ¡Olé!

##### `get-psgi-app`

Returns a PSGI / P6SGI / P6W app which should be able to run on different Servers.

#### Subroutines that sould only be used inside the Code block of a Route

##### `content_type(Str $type)`

Sets the Content Type for the response to $type.

##### `request()`

Gets current the Request.

##### `header(Str $name, Cool $value)`

Adds a Header to the Repsonse.

##### `cookie(Str $name, Str $value, Str :$domain, Str :$path, DateTime :$expires, Bool :$http-only; Bool :$secure)`

Adds a Cookie to the response.

##### `status(Int $code)`

Sets the status code of a response.

#####  `template(Str $template-name, *@params)`

Calls the template which is a file in the views folder. For more details see the Template section. Should only be used within the code block of a route.

##### `session()`

Returns the Session Hash. Session Hashes are empty if you start a new session. For details see the Sessions section.

## Web Applications via Inheriting from `Bailador::App`

```Perl6
class MyWebApp is Bailador::App {
    submethod BUILD(|) {
        my $rootdir = $?FILE.IO.parent.parent;
        self.location = $rootdir.child("views").dirname;
        self.sessions-config.cookie-expiration = 180;

        self.get:  '/login' => sub { self.session-delete; self.template: 'login.tt' };
        self.post: '/login' => self.curry: 'login-post';

        my $only-if-loggedin = Bailador::Route.new: path => /.*/, code => sub {
            return True if self.session<user>;
            return False;
        };
        $only-if-loggedin.get:  '/the/app'  => sub { ... };
        self.add_route: $only-if-loggedin;

        self.add_route: Bailador::Route::StaticFile.new: path => / (<[\w\.]>+ '/' <[\w\.\-]>+)/, directory => $rootdir.child("public");
        self.get: / .* / => sub {self.redirect: '/login' };

    }
    method login-post { ... }
}
```

### Nested Routes

Routes can be nested and structured in a tree. If you just use the methods get, post, etc from the Bailador::App all the routes that you add are placed on the first level of the tree, so nothing is nested so far.
Nesting routes make sense if you want to enter routes just under conditions. The most perfect example when nested routes become handy is when you want to serve content just when someone is logged in. Instead of having the same check spread over and over in each and every sub you just create a `Bailador::Route` and add it with `self.add_route`. So the return value of the route now determines what to do.

### Auto Rendering

Auto rendering means that whatever (except `True` and `False`) the return value of the sub is, it will be rendered. Using `self.render` will turn of auto rendering, because you obviously have rendered something manually. In the classical approach auto rendering is always used.

### Return Values of Routes

  * `False`

    The callable of a route works as a conditional check and the nested routes will not be checked nor invoked. It behaves as if the route would not have matched at all. So it will continue to look for a route that matches your request.

  * `True`

    The callable of a route works as a conditional check and allows to go deeper into the tree. In case nothing in the tree matches the request an exception is thrown. That causes to leave the nested routes and continue checking for other routes. Of course, if this happens in the first level of the tree a `404` is created.

  * `Failure`s and `Exception`s

    This will cause a HTTP `500`

  * anything that is not `defined`

    It is fine if a route returns nothing (e.g. `Nil` or `Any`) or anything that is not defined as long as you have rendered something within the callable of the route.

  * anything that is `defined`

    If anything defined is returned this will be the content of the response as long as you don't have rendered something in the callable of the route. Using `self.render` will turn off auto rendering.

### Bailador::Route::StaticFile

```Perl6
my $files = Bailador::Route::StaticFile.new: directory => $dir, path => '/public/:file';
self.add_route: $files;
```

A static file route can be used to serve files in a directory. The `path` `Regex` or `Str` must return a single match which will be turned into a `.Str`. If there is a file in the directory with that name it will be rendered otherwise the route returns a `False`, so in the end the route is left and maybe other routes can handle your request.

## Templates

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

    
## Sessions

Sessions are implemented using a Session Cookie. If the browser rejects cookies, Bailador is not able to handle sessions.

In order to create a session just call the subroutine

    session()
    
inside the code block of a route. This subroutine returns a Hash in which you can just toss in all data or objects that should be be in the session context.
After your route code is finished the session will be stored automatically. How this should be done can be configured.
The handling of sessions can be influencend if you call

    sessions-config()
    
inside the bailador script before you call baile. As soon as you have requested the first session it is of no use to change the configure any further.
Following config options are available. Most of them should be self explaining.

* cookie-name = 'bailador';
* cookie-path = '/';
* cookie-expiration = 3600;
* hmac-key = 'changeme';
* backend = "Bailador::Sessions::Store::Memory";

The Session-ID contains a HMAC to check if someone's trying to guess a Session-ID in order to hijack a session. This case it will create a warning which is printed to standard error.

The Session Data itself is stored by default in the memory, if you want to store the data on the disk or database of wherever, just implement a class which does the role Bailador::Sessions::Store
and set backend to this class name.


## Bailador-based applications

* https://github.com/szabgab/Perl6-Maven serving http://perl6maven.com/
* https://github.com/perl6/cpandatesters.perl6.org/ used to serve http://testers.p6c.org/ but currently not in use


## Articles about Bailador
http://perl6maven.com/bailador

## License

MIT License
