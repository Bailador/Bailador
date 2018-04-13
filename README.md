[![Build Status](https://travis-ci.org/Bailador/Bailador.png)](https://travis-ci.org/Bailador/Bailador)
[![Build status](https://ci.appveyor.com/api/projects/status/github/Bailador/Bailador?svg=true)](https://ci.appveyor.com/project/ufobat/Bailador/branch/dev)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/bailador/Bailador.svg)](http://isitmaintained.com/project/bailador/Bailador "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/bailador/Bailador.svg)](http://isitmaintained.com/project/bailador/Bailador "Percentage of issues still open")
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/maintenance/yes/2017.svg)]()

# NAME

Bailador

# SYNOPSIS

```perl6
use Bailador;

get '/' => sub {
    "Hello World";
}

baile();
```

# DESCRIPTION

Bailador is a light-weight route-based web application framework for Perl 6. Talk to the developers at https://perl6-bailador.slack.com/

# INSTALLATION

Once you have [Rakudo Star](http://rakudo.org/) installed open a terminal (or command line on Windows) and type:
```
$ zef update
$ zef install Bailador
```
This should download and install Bailador.

You can test your installation, and see what is your Bailador installed version with the following command:
```
$ bailador version
```
NB: If you are using Rakudobrew you may need to run the following command to make `bailador` available in your terminal:
```
$ rakudobrew rehash
```

# GETTING STARTED

At the command prompt, create a new Bailador application:
```
$ bailador --name App-Name new
```
Then, change directory to `App-Name` and start the web server:
```
$ bailador watch bin/app.pl6
```
That's it!
Using a browser, go to http://localhost:3000. Isn't it wonderful?

You can now edit the files and Bailador reloads the application while you're developing.

If you want to learn more about Bailador, please visit our [documentation](doc/README.md).

# EXAMPLES

For more examples, please see the [examples](examples) folder.

# BAILADOR RESOURCES

You can find a list of Bailador resources (articles, posts, talks, books, ...) [here](https://github.com/Bailador/Ressources).

## Bailador-based applications

* https://github.com/szabgab/Perl6-Maven serving http://perl6maven.com/
* https://github.com/perl6/cpandatesters.perl6.org/ used to serve http://testers.p6c.org/ but currently not in use

## Related projects

https://github.com/pnu/heroku-buildpack-rakudo

# CONTRIBUTION

[![GitHub contributors](https://img.shields.io/github/contributors/bailador/bailador.svg)](https://github.com/Bailador/Bailador/graphs/contributors)

We encourage you to contribute to Bailador! If you'd like to do that,
see first the [CONTRIBUTING](CONTRIBUTING.md) document.

# LICENSE

Bailador is released under the MIT License.



