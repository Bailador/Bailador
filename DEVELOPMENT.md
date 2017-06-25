
## Setup Environment

If you'd like to contribute to Bailador you need to `fork` the [GitHub](https://github.com/Bailador/Bailador) repository and clone the forked repo to your hard disk. Then you need to install all the dependencies of Bailador:

```
cd Bailador
zef --depsonly install .
```

Run the tests that come with Bailador to make sure everything passes *before* your start making changes. Run:
```
prove6 -l
```
or
```
prove -e 'perl6 -Ilib' t
```

The rest is "standard" GitHub process. Talk to us on our [Slack channel](https://perl6-bailador.slack.com/)


## Release

* Install mi6 package `zef install mi6`
* Run `mi6`
* Update the VERSION number in the META6.yml
* Verify the list of changes in the Changes file
* Upload to PAUSE

