
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

* Upgrade the version in META6.json
* Check for missings entries in the Change file (git log)
* Commit and Push this changes to the dev branch.
* Merge dev in main and tag it with the current version.
   - `git checkout main`
   - `git pull`
   - `git merge dev`
   - `git tag 0.x.y`
   - `git push`
   - `git push origin 0.x.y`
* Install mi6 package `zef install App:Mi6`
* Run `mi6 dist`
* Revert Changes to README.md with `git checkout README.md` (Ticket #151)
* Copy README.md to Bailador-0.x.y/README.md
* Build the tarball with `tar cvfz Bailador-0.x.y.tar.gz Bailador-0.x.y`
* Upload to PAUSE

