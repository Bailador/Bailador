# Bailador

[![Build Status](https://travis-ci.org/Bailador/Bailador.png)](https://travis-ci.org/Bailador/Bailador)
[![Build status](https://ci.appveyor.com/api/projects/status/github/Bailador/Bailador?svg=true)](https://ci.appveyor.com/project/ufobat/Bailador/branch/dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A light-weight route-based web application framework for Perl 6.

Talk to the developers at https://perl6-bailador.slack.com/

# TABLE OF CONTENTS
- [Install](#install)
- [Contribution](#contribution)
- [Versioning model](#Versioning-model)
- [Examples](#examples)
- [Skeleton](#skeleton)
- [How to Start Apps](#how-to-start-apps)
    - [bailador](#bailador)
    - [Crust](#crust)
    - [Baile](#baile)
- [How to Write Web Apps](#how-to-write-web-apps)
    - [Mixing both Approaches](#mixing-both-approaches)
    - [Classical Approach](#classical-approach)
        - [Subroutines for your Application](#subroutines-for-your-application)
            - [`app(Bailador::App $app)`](#appbailadorapp-app)
            - [`get(Pair $x)`](#getpair-x)
            - [`post(Pair $x)`](#postpair-x)
            - [`put(Pair $x)`](#putpair-x)
            - [`delete(Pair $x)`](#deletepair-x)
            - [`prefix(Pair $x)`](#prefixstr-prefix-callable-code)
            - [`prefix-enter(Callable $code)`](#prefix-entercallable-code)
            - [`redirect(Str $location)`](#redirectstr-location)
            - [`renderer(Bailador::Template $renderer)`](#rendererbailadortemplate-renderer)
            - [`config()`](#config)
            - [`set(Str $key, $value)`](#setstr-key-value)
            - [`baile()`](#baile)
        - [Subroutines that should only be used inside the Code block of a Route](#subroutines-that-sould-only-be-used-inside-the-code-block-of-a-route)
            - [`content_type(Str $type)`](#content_typestr-type)
            - [`request()`](#request)
            - [`uri-for(Str $path)`](#uri-forstr-path)
            - [`header(Str $name, Cool $value)`](#headerstr-name-cool-value)
            - [`cookie(Str $name, Str $value, Str :$domain, Str :$path, DateTime :$expires, Bool :$http-only; Bool :$secure)`](#cookiestr-name-str-value-str-domain-str-path-datetime-expires-bool-http-only-bool-secure)
            - [`status(Int $code)`](#statusint-code)
            - [`template(Str $template-name, *@params)`](#templatestr-template-name-params)
            - [`session()`](#session)
            - [`to-json()`](#to-json)
    - [Web Applications via Inheriting from `Bailador::App`](#web-applications-via-inheriting-from-bailadorapp)
        - [Nested Routes](#nested-routes)
        - [Auto Rendering](#auto-rendering)
        - [Return Values of Routes](#return-values-of-routes)
        - [Bailador::Route::StaticFile](#bailadorroutestaticfile)
- [Templates](#templates)
    - [Error Templates](#error-templates)
- [Sessions](#sessions)
- [Configuration](#configuration)
- [Bailador-based applications](#bailador-based-applications)
- [Articles about Bailador](#articles-about-bailador)
- [License](#license)

## Install

Once you have [Rakudo Star](http://rakudo.org/) installed open a terminal (or command line on Windows) and type:
```
zef update
zef install Bailador
```
This should download and install Bailador.

You can test your installation, and see what is your Bailador installed version with the following command:
```
bailador version
```

## Contribution

If you'd like to contribute to Bailador see the [DEVELOPMENT](DEVELOPMENT.md).

## Versioning model

The Baildor repository holds two main branches with an infinite lifetime :

 - Main branch :

 We consider `origin/main` to be the main branch where the source code of HEAD always reflects a production-ready state.

 - Dev branch :

 We consider `origin/dev` to be the branch where the source code of HEAD always reflects a state with the latest delivered development changes for the next release.

When the source code in the `dev` branch reaches a stable point and is ready to be released, all of the changes are merged back into `main` and then tagged with a release number.


## Examples

For more examples, please see the [examples](examples) folder.

## Skeleton

Run

```
bailador --name App-Name new
```
to create a skeleton project.

## How to Start Apps

### Crust

When you have installed [Crust](http://modules.perl6.org/dist/Crust) from the Perl 6 ecosystem there is a command called `crustup` or `crustup.bat` which can be used to launch your Bailador App. Bailador was developed and runs best on top of [HTTP::Easy::PSGI](http://modules.perl6.org/dist/HTTP::Easy). Always use `baile()` at the end of your app, because in the default configuration it guesses whether your app is called via `crustup` or directly with `perl6`. Depending on that `baile()` chooses the right `Bailador::Command` to invoke your application with.

#### Example

Store this Example in a file called `example.p6w`

```Perl6
use v6;
use Bailador;

# simple cases
get '/' => sub {
    "hello world"
}

baile();
```

and then type this in your shell:

`crustup --server HTTP:::Easy example.p6w`

### bailador

`bailador` can be used to start your bailador web application. The command line tool converts the command line switches (e.g. `--config=port:8080`) to environment variables (`%*ENV`). There are different commands for bailador.

#### `--config`

Takes a comma-separated list of parameters that configure various aspects of how Bailador will run. `--config` overrides the [BAILADOR](#configuration) environment variable.
For details of the available configuration parameters check the [Configuration](#configuration) section of the documentation.
Currently available parameters:

```
    bailador --config=host:0.0.0.0,port:3001 watch bin/your-bailador-app.p6
```

#### `bailador easy`

The command easy starts the the web application with the HTTP::Easy::PSGI backend.

#### `bailador watch`

The command watch watches the source code of your Bailador app for changes and automatically restart the app.

##### `--w`

Takes comma-separated list of directories to watch. By default,
will watch the `lib`, `bin`, and `views` directories.

If you have to watch a directory with a comma in its name, prefix it with a backslash:

    bailador --w=x\\,y bin/app.p6  # watches directory "x,y"

    bailador --w=lib,bin,views,public watch bin/your-bailador-app.p6


### Baile

In order to invoke the Bailador App directly, you could simply call baile() in your script.

```Perl6
use v6;
use Bailador;

# simple cases
get '/' => sub {
    "hello world"
}

baile;
```

This will launch the Bailador server on default port 3000.

## How to Write Web Apps

Bailador offers two different approaches to write web applications. The first and classical approach is using the subs that are exported that you get when you `use Bailador`. This API is meant to be stable and should not change much.

New features like nested routes and whatever is yet to come are implemented in `Bailador::App` and can be used through the object oriented interface. Your own web application just inherits from `Bailador::App`.

### Mixing both Approaches

When you write your own application, but still want to use the exported subs described in [this](#subroutines-that-should-only-be-used-inside-the-code-block-of-a-route) section you MUST set your `$app` to be the default app.

```Perl6
use v6;
use Bailador;
use Bailador::App;

class MyWebApp is Bailador::App { ... }
my $app = MyWebApp.new;

app $app;
```

### Classical Approach

#### Subroutines for your Application

#### `app(Bailador::App $app)`

Sets a Bailador::App to be the default app for all the other exported subs described in [Subroutines that should only be used inside the Code block of a Route](#subroutines-that-should-only-be-used-inside-the-code-block-of-a-route).

##### `get(Pair $x)`
##### `post(Pair $x)`
##### `put(Pair $x)`
##### `delete(Pair $x)`

Adds a route for get, post, put or delete requests. The key of the
`Pair` is either a `Str` or a `Regex`. If a string is passed it is
automatically converted into a regex. The value of the pair must be a
`Callable`. Whenever the route matches the requested URL the
callable is invoked with the list of the `Match` as its
parameters. The return value of the callable will be auto rendered. So
it is the content of your response. The request is available via the
appropriately named variable `request`; `request.params` will contain
the route parameters, for instance; `request.params<q>` will yield the
value for param `q`.

The strings captured by the regular expression are available as
subroutine parameters.

```Perl6
    get "/foo/(.+)" => sub ( $route ) {
        return "What a $route";
    }
```

##### `prefix(Str $prefix, Callable $code)`
##### `prefix-enter(Callable $code)`

The prefix sets up a [Nested Route](#nested-routes). All other routes that will be added within the $code will be added to this nested route. With prefix-enter you can define code that will be called whenever the prefix matches your HTTP request. Only if this code returns True the routes within the prefix can be reached during request dispatching. Without using prefix-enter the routes in the prefix are reachable - this means the default code for a prefix route is ``` sub { True } ```.

```Perl6
    prefix "/foo" => sub {
        prefix-enter sub {
            ... something that returns True or False ...
        }
        get "/bar" => sub { ... }
        get "/baz" => sub { ... }
    }
```

##### `redirect(Str $location)`

Redirect to the specified location, can be relative or absolute URL. Adds Location-header to response and sets status code to 302.

##### `renderer(Bailador::Template $renderer)`

Sets the Renderer that's being used to render your templates. See the [Templates](#templates) section for more details.

##### `config()`

Returns the configuration. You can influence how sessions work, the mode, port and host of your Bailador app.
See the [Sessions](#sessions) and [Configuration](#configuration) sections for details.

##### `set(Str $key, $value)`

This is a simple way to set values in the config.

```perl6
    # this:
    set("foo", True);
    # is doing exactly the same as this:
    config.foo = True;
```

##### `baile()`

or `baile($command)`

Let's enter the dance floor. ¡Olé!

#### Subroutines that should only be used inside the Code block of a Route

##### `content_type(Str $type)`

Sets the Content Type for the response to $type.

##### `request()`

Gets the object representing the current Request.

##### `uri-for(Str $path)`

Constructs a URI String from the base and the passed $path.

##### `header(Str $name, Cool $value)`

Adds a Header to the Response.

##### `cookie(Str $name, Str $value, Str :$domain, Str :$path, DateTime :$expires, Bool :$http-only; Bool :$secure)`

Adds a Cookie to the response.

##### `status(Int $code)`

Sets the status code of a response.

#####  `template(Str $template-name, :$layout, *@params)`

Calls the template which is a file in the views folder. You can specify a $:layout if you want to override the settings in Bailador::Configuration.
For more details see the Template section. Should only be used within the code block of a route.

##### `session()`

Returns the Session Hash. Session Hashes are empty if you start a new session. For details see the Sessions section.

#### `to-json()`

Converts your data into JSON format using JSON::Fast.

### Web Applications via Inheriting from `Bailador::App`

```Perl6
class MyWebApp is Bailador::App {
    submethod BUILD(|) {
        my $rootdir = $?FILE.IO.parent.parent;
        self.location = $rootdir.child("views").dirname;
        self.config.cookie-expiration = 180;

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

#### Nested Routes

Routes can be nested and structured in a tree. If you just use the methods get, post, etc from the Bailador::App all the routes that you add are placed on the first level of the tree, so nothing is nested so far.
Nesting routes make sense if you want to enter routes just under conditions. The most perfect example when nested routes become handy is when you want to serve content just when someone is logged in. Instead of having the same check spread over and over in each and every sub you just create a `Bailador::Route` and add it with `self.add_route`. So the return value of the route now determines what to do.

#### Auto Rendering

Auto rendering means that whatever (except `True` and `False`) the return value of the sub is, it will be rendered. Using `self.render` will turn of auto rendering, because you obviously have rendered something manually. In the classical approach auto rendering is always used.

#### Return Values of Routes

  * `False`

    The callable of a route works as a conditional check and the nested routes will not be checked nor invoked. It behaves as if the route would not have matched at all. So it will continue to look for a route that matches your request.

  * `True`

    The callable of a route works as a conditional check and allows to go deeper into the tree. In case nothing in the tree matches the request an exception is thrown. That causes to leave the nested routes and continue checking for other routes. Of course, if this happens in the first level of the tree a `404` is created.

  * `Failure`s and `Exception`s

    This will cause a HTTP `500`

  * anything that is not `defined`

    It is fine if a route returns nothing (e.g. `Nil` or `Any`) or anything that is not defined as long as you have rendered something within the callable of the route.

  * anything that is `defined`

    If anything defined is returned this will be the content of the response as long as you don't have rendered something in the callable of the route. If an `IO::Path` gets returned it automatically guesses its content type based on the filename extensions and renders the content of the file.

Using `self.render` will turn off auto rendering.

#### Bailador::Route::StaticFile

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

The template files should be placed by default in a folder named "views" which is located in the same directory as your application.pl file. If you want to override this, you just have to change the  `views` settings, and choose you own directory :
```yaml
views: "templates"
```

When you call the subroutine

    template 'template.tt', $name, $something;

the template (or in other words the file views/template.tt) gets invoked "as a subroutine" and the |@params get passed. This is a example of a template file with Template::Mojo:

    % my ($name, $something) = @_;
    <html ... codes goes here ...>
        <h1><%= $name %></h1>
    <html>

### Layouts

In order to use layouts you can pass a layout option to the `template()` call.

    template 'template.tt', layout => 'main', $name, $something;

First Bailador renders your template with its parameters, and then scans the 'layout' sub directory for another layout template. The same rendering engine will be used for the layout template. The result of your first template rendering will be passed as only option to layout template. If the specified layout was not found the result of the first template rendering will be returned.

### Error Templates

In order to customize the error pages drop a template file with the filename of the HTTP status code and the suffix `.xx` in your views directory. Currently there only two different error codes: `404` and `500`.

## Sessions

Sessions are implemented using a Session Cookie. If the browser rejects cookies, Bailador is not able to handle sessions.

In order to create a session just call the subroutine

    session()

inside the code block of a route. This subroutine returns a Hash in which you can just toss in all data or objects that should be be in the session context.
After your route code is finished the session will be stored automatically. How this should be done can be configured.
The handling of sessions can be influenced with settings of Bailador::Configuration.

    config()

inside the bailador script before you call `baile`. As soon as you have requested the first session it is of no use to change the configure any further.
Following config options are available. Most of them should be self explanatory.

* cookie-name = 'bailador';
* cookie-path = '/';
* cookie-expiration = 3600;
* hmac-key = 'changeme';
* backend = "Bailador::Sessions::Store::Memory";

The Session-ID contains a HMAC to check if someone's trying to guess a Session-ID in order to hijack a session. This case it will create a warning which is printed to standard error.

The Session Data itself is stored by default in the memory, if you want to store the data on the disk or database of wherever, just implement a class which does the role Bailador::Sessions::Store
and set backend to this class name.

## Configuration

Bailador uses a default configuration, but you can customize it, using the Bailador environment variable, or using configuration files. You can also change the configuration within your app. The Bailador::Configuration can also store custom-specific information, therefore please use the `set` / `get` method. The order of adjusting the settings is: first the code in your app, second from the configuration files, third from the environment variables. So the settings from the environment variable `BAILADOR` will finally override what you might have stated in the config files.

```perl6
# directly
config.port      = 8080;
config.hmack-key = 'xxxxxx';

# or via set()
config.set('port', 8080);

# set works for custom values as well
config.set('custom-key', 'value')
config.set('database-username', 'ufobat')
config.set('database-password', 'xxxxxx')

```

For now, Bailador only allows you to use YAML formatted configuration files. The default configuration file name is `settings.yaml`, but you could change this if you like. Just write `config.config-file = 'myconfig.yaml'` in the beginning of your app. Create at the root of your project directory a `settings.yaml` file :

```yaml
# settings.yaml
mode: "development"
port: 8080
```

Bailador will now generate 2 more config file variants and process the settings from there. In our example `settings-local.yaml` and, depending on our `config.mode` which is development, a file named `settings-development.yaml`. If our mode was production Bailador would have used `settings-production.yaml`.

This allows you to have a general settings.yaml that you which to use on everywhere. Adaptions that only apply to a certain server could be placed into the `-local` configuration file. And settings that only apply during development mode can be stored in the `-development` file. As soon as you switch to production mode those settings will no longer be used.

Using the `BAILADOR` environment variable is a comma separated list of key-value pairs.

```
BAILADOR=mode:development,host:0.0.0.0,port:5000 perl6 examples/app.pl6
```

Currently available parameters:

* config-file       (defaults to 'settings.yaml')
* mode              (defaults to 'production')
* port              (defaults to 3000)
* host              (defaults to 127.0.0.1)
* views
* layout
* command-detection (defaults to True)
* default-command
* watch-command     (defaults to 'easy')
* watch-list
* cookie-name       (defaults to 'bailador')
* cookie-path       (defaults to = '/)
* cookie-expiration (defaults to 3600)
* hmac-key          (defaults to 'changeme')
* backend           (defaults to "Bailador::Sessions::Store::Memory")
* log-format        (defaults to '\d (\s) \m'
* log-filter        (defaults to `( 'severity' => '>=warning')`)

## Bailador-based applications

* https://github.com/szabgab/Perl6-Maven serving http://perl6maven.com/
* https://github.com/perl6/cpandatesters.perl6.org/ used to serve http://testers.p6c.org/ but currently not in use


## Articles about Bailador

http://perl6maven.com/bailador

## Book about Bailador

In the planning phase, currently crowdfunding it: https://leanpub.com/bailador

## License

MIT License

## Related projects

https://github.com/pnu/heroku-buildpack-rakudo
