## Versioning model

The Baildor repository holds two main branches with an infinite lifetime :

 - Main branch :

 We consider `origin/main` to be the main branch where the source code of HEAD always reflects a production-ready state.

 - Dev branch :

 We consider `origin/dev` to be the branch where the source code of HEAD always reflects a state with the latest delivered development changes for the next release.

When the source code in the `dev` branch reaches a stable point and is ready to be released, all of the changes are merged back into `main` and then tagged with a release number.

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

* Install mi6 package `zef install App:Mi6`
* Upgrade the version in lib/Bailador.pm
* Run 'mi6 build' in order to update the META6.json
* Check for missings entries in the Change file (git log)
* Commit and push this changes to the dev branch.
* Merge dev in main and tag it with the current version.
   - `git checkout main`
   - `git pull`
   - `git merge dev`
   - `git tag 0.x.y`
   - `git push`
   - `git push origin 0.x.y`
* Run `mi6 dist`
* Upload to PAUSE
