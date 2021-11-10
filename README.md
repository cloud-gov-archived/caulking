e  Caulking stops leaks

![caulking gun with grey caulk oozing out](https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Caulking.jpg/757px-Caulking.jpg)

Goals:

* Simplify installation of git leak prevention and rules with `make install`
* Simplify auditing local systems for leak prevention with `make audit`
* Support adding and testing rules

## Installation notes

This assumes you are on MacOS with HomeBrew installed. `make install` will brew install `gitleaks`. The install will:

* install `gitleaks`
* add a global `pre-commit` hook to `$HOME/.git-support/hooks/pre-commit`
* add the configuration with patterns to `$HOME/.git-support/gitleaks.toml`

You now have the gitleaks pre-commit hook enabled globally.

To get rid of `git-seekrets` configuration, run `make clean_seekrets`

## Bug warning!

If you get the error `reference not found` on a new repository, be sure you've run `brew upgrade gitleaks` to install version 4.1.1 or later.

## Auditing notes - how to test if this is working

The `make audit` target installs prerequisites then runs the test harness `bats caulked.bats` and outputs whether the tests pass or fail. All tests must pass to be considered a successful install/audit.

The tests check for a working `gitleaks` setup, and that you haven't inadvertently disabled `gitleaks` in your repositories. It checks:

* that common patterns of secrets cause a commit to fail
* that `hooks.gitleaks` is set to true underneath $HOME to $MAXDEPTH setting
* that any custom `/.git/hooks/pre-commit` scripts also still call `gitleaks`

These assume a compliant engineer who wants to abide by use of `gitleaks`,and  doesn't deliberately subvert that intent.

## What now?

You have installed gitleaks and our patterns, and you've verified that all of your repositories are not inadvertently sidestepping the caulking. Continue on with your day. We may periodically ask you to run `make patterns` and `make audit` to update your rules and test that you are still protected from committing known secret patterns.

If you get a `git commit` error message like this:

```
{
	"line": "Juana M. is at juana@example.com",
	"offender": "javier@example.com",
	"commit": "0000000000000000000000000000000000000000",
	"repo": "gittest.ffqOwg",
	"rule": "Email",
	"commitMessage": "***STAGED CHANGES***",
	"author": "",
	"email": "",
	"file": "secretsfile.md",
	"date": "1970-01-01T00:00:00Z",
	"tags": "email"
}
```

Then, remove or fix the offending line.

### But what if the "offending line" isn't a secret?

You have a couple of choices:

* Submit a PR to improve our patterns (guidance forthcoming)
* Submit an issue to this repo, and then ignore `gitleaks` _temporarily_ with:

        git config --local hooks.gitleaks false
        git commit -m "message" 
        git config --local hooks.gitleaks true

You may want to add function to your `.bashrc` profile like:

```
gitforce() {
    read -p "You are about to commit a potential secret. Are you sure? " -n 1 -r
        echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        git config --local hooks.gitleaks false
        git commit -m "$@" 
        git config --local hooks.gitleaks true
    fi
}
```

# Development tips

To add a new test case:

* add it to `development.bats`
* run `bats development.bats`
* it should fail, since you've not yet updated local.toml
* work on local.toml until `bats development.bats` passes

Here are some shortcuts when you're ready to test the whole package

- `make hook`: update `~/.git-support/hooks/pre-commit` from local `pre-commit.sh`
- `make patterns`: update the `gitleaks` configuration in `~/.git-support/gitleaks.toml` from local `local.toml` 
- `make audit`: see that everything work together.

## Testing bats tests

To test bats tests, start a subshell, load in the functions from `test_helper.bash`,
then be sure to run `setup` before any test to populate `$REPO_PATH` and so on.  For
example:

``` sh
bash # start a new shell
source test_helper.bash # load all the helper functions
setup 
addFileWithNoSecrets # do the failing thing 
echo $?
^D
```

## Rule sets

The following rule sets helped inform our gitleaks.toml:

* https://github.com/GSA/odp-code-repository-commit-rules/blob/master/gitleaks/rules.toml - used for guidance
* https://github.com/zricethezav/gitleaks/blob/master/examples/leaky-repo.toml - used verbatim except for removing certain rulesets.

## What about other hooks? Will they still run?

Yes. Caulking runs your other precommit hooks automatically. 

Note: if you're using [pre-commit](https://pre-commit.com/) to manage pre-commit hooks, you'll likely get an error like this when running `pre-commit install`:
```
[ERROR] Cowardly refusing to install hooks with `core.hooksPath` set.
hint: `git config --unset-all core.hooksPath`
```
You can work around this by running:
```
hookspath=$(git config core.hookspath)
git config --global --unset-all core.hookspath
pre-commit install
git config --global core.hookspath "${hookspath}"
```

## Incompatible gitleaks changes

Sometimes gitleaks updates will have breaking changes, and you'll need to compare gitleaks
between the current version and an older version. To install an older gitleaks version with `brew`:

* Browse the [brew history for the gitleaks formula](https://github.com/Homebrew/homebrew-core/commits/master/Formula/gitleaks.rb)
* Find the `commit` that matches the older version you want to roll back to
* Then run: 
  ```
  wget https://raw.githubusercontent.com/Homebrew/homebrew-core/<commit>/Formula/gitleaks.rb
  brew unlink gitleaks
  brew install ./gitleaks.rb
  ```
* You'll now have the older version. 

# Public domain

This project is in the worldwide public domain. As stated in CONTRIBUTING:

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication.

> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
