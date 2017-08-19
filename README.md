# Bailador

[![Build Status](https://travis-ci.org/Bailador/Bailador.png)](https://travis-ci.org/Bailador/Bailador)
[![Build status](https://ci.appveyor.com/api/projects/status/github/Bailador/Bailador?svg=true)](https://ci.appveyor.com/project/ufobat/Bailador/branch/dev)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/bailador/Bailador.svg)](http://isitmaintained.com/project/bailador/Bailador "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/bailador/Bailador.svg)](http://isitmaintained.com/project/bailador/Bailador "Percentage of issues still open")
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/maintenance/yes/2017.svg)]()

A light-weight route-based web application framework for Perl 6.

Talk to the developers at https://perl6-bailador.slack.com/

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

## Getting Started

At the command prompt, create a new Bailador application :
```
bailador --name App-Name new
```
Then, change directory to `App-Name` and start the web server:
```
bailador easy bin/app.pl6
```
That's it !
Using a browser, go to http://localhost:3000. Wonderful ?

If you want to learn more about Bailador, please visit our [documentation](doc/README.md).

## Examples

For more examples, please see the [examples](examples) folder.

## Contributing

[![GitHub contributors](https://img.shields.io/github/contributors/bailador/bailador.svg)]()

We encourage you to contribute to Bailador !

If you'd like to contribute to Bailador, see the [DEVELOPMENT](doc/DEVELOPMENT.md).

## Versioning model

The Baildor repository holds two main branches with an infinite lifetime :

 - Main branch :

 We consider `origin/main` to be the main branch where the source code of HEAD always reflects a production-ready state.

 - Dev branch :

 We consider `origin/dev` to be the branch where the source code of HEAD always reflects a state with the latest delivered development changes for the next release.

When the source code in the `dev` branch reaches a stable point and is ready to be released, all of the changes are merged back into `main` and then tagged with a release number.

## Bailador-based applications

* https://github.com/szabgab/Perl6-Maven serving http://perl6maven.com/
* https://github.com/perl6/cpandatesters.perl6.org/ used to serve http://testers.p6c.org/ but currently not in use


## License

Bailador is released under the MIT License.

## Related projects

https://github.com/pnu/heroku-buildpack-rakudo
