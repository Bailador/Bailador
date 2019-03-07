## Setup Environment

If you'd like to contribute to Bailador you need to `fork` the [GitHub](https://github.com/Bailador/Bailador) repository and clone the forked repo to your hard disk. Then you need to install all the dependencies of Bailador:

```
$ cd Bailador
$ zef --depsonly install .
```

Run the tests that come with Bailador to make sure everything passes *before* your start making changes. Run:
```
$ prove6 -l
```
or
```
$ prove -e 'perl6 -Ilib' t
```

Even more tests can be run by
```
AUTHOR_TESTING=1 prove6 -l
```


The rest is "standard" GitHub process. Talk to us on our [Slack channel](https://perl6-bailador.slack.com/)

## How to make a release

* Install mi6 package `zef install App:Mi6`.
* use the mi6 workflow to release Bailador to CPAN.
