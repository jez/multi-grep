# multi-grep

[![Buildmulti-grep Status](https://travis-ci.org/jez/multi-grep.svg?branch=master)](https://travis-ci.org/jez/multi-grep)

> Search for a pattern on specific lines

By default, `grep` searches for a given pattern on **all** lines in a file.
Sometimes that is too coarse grained. By contrast, `multi-grep` searches for a
pattern only on the specified lines.

`multi-grep` takes input that looks like

```
filename.txt:17
filename.txt:42
another.md:12
another.md:23
```

and searches for a regular expression only on the file + line combinatines
specified in the input. When a match is found, the `filename:line` combination
that was being searched is printed. In this way, `multi-grep` is a Unix-style
pipeline filter.

If `grep` is like a chainsaw, `multi-grep` is more like a scalpel. Using a
combination of tools like `git grep -l` and `awk` with `multi-grep`, we can
construct precise filters. Specifically, two other tools are particularly useful
in conjunction with `multi-grep`:

- [diff-locs] is a tool that converts a unified diff into input suitable for
  `multi-grep`.

- [multi-sub] is like `multi-grep`, but with `sed -e 's/.../.../'`.

`multi-grep` is fast. It's implemented in Standard ML, compiled with the [MLton]
optimizing compiler, and has been repeatedly profiled to improve performance. It
only does work that's absolutely needed.

[diff-locs]: https://github.com/jez/diff-locs
[multi-sub]: https://github.com/jez/multi-sub


## Usage

This is the help for `multi-grep` version `0.2.2`. It might be out of date—run
`multi-grep --help` locally for up-to-date help.

```
❯ multi-grep --help
Usage:
  multi-grep [options] <pattern> [<locs.txt>]

Searches in the mentioned lines for the pattern and prints the lines
that contain a match.

Arguments:
  <pattern>      An AWK-compatible[1] regular expression.
  <locs.txt>     The name of a file with lines formatted like:
                   filename.ext:20
                 If omitted, reads from stdin.

Options:
  -i, --ignore-case     Treat the pattern as case insensitive.
  -s, --case-sensitive  Treat the pattern as case sensitive [default].
  -v, --invert-match    Print the location if there isn't a match there.
  --version             Print version and exit.

[1]: http://www.smlnj.org/doc/smlnj-lib/Manual/parser-sig.html
```


## Install

There are pre-compiled binaries for macOS and Linux.
You can also install from source.

### macOS

Using Homebrew:

- `brew install jez/formulae/multi-grep`

Or, download the binary directly from the releases:

- <https://github.com/jez/multi-grep/releases/download/latest>

### Linux

Download the binary from the releases page:

- <https://github.com/jez/multi-grep/releases/download/latest>

### From source

The project is built using [MLton]. You will need to install this for your
platform.

[MLton]: http://mlton.org

Fetch source (including submodules):

```
git clone --recursive https://github.com/jez/multi-grep
```

Build:

```
./symbol make with=mlton
```

Install:

```shell
# installs to ~/.local/bin
./symbol install

# installs to $prefix
./symbol install prefix="$prefix"
```

## Contributing

`multi-grep` is written in Standard ML, and uses [Symbol] to build. To develop
locally, you'll need both [SML/NJ] and [MLton] installed. If you don't want to
do this or you can't get one of these installed on your development environment,
push your changes to a branch on GitHub and CI will automatically run.

### About Symbol

[Symbol] is a build tool for Standard ML. It's designed to work alongside and on
top of existing SML build tools, like SML/NJ's CM and MLton's MLBasis files.

It works using a shell script and makefile that are checked into this repo, so
you don't have to install anything yourself (unless you want to initialize a new
Symbol-powered project).

While not required, for conveninence you might want to add some directories to
your `PATH` when using `Symbol`:

```bash
# this is to be able to run executables without a path prefix
export PATH="$PATH:.symbol-work/bin"
# this is to be able to run `symbol` instead of `./symbol`
export PATH="$PATH:."
# this is where `symbol install` installs executables globally
export PATH="$PATH:$HOME/.local/bin"
```

See [the Symbol README][Symbol] for more information.

### Quickref

The most common commands you're likely to use:

```bash
# Build for development (fast recompilation, but slow execution)
./symbol make

# Build for release (slow recompilation, but fast execution):
./symbol make with=mlton

# Run after building:
.symbol-work/bin/multi-grep

# Check code style:
make lint

# Run the tests:
./run-tests.sh

# Run the tests, and update all snapshots:
./run-tests.sh --update
```

### Writing tests

Tests live in the `tests/` folder. The nesting structure of subfolders is not
significant. Tests are written as CLI snapshot tests. Each test consists of a
pair of files:

- `$my_test_name.in`: the input to the test

  The first line of this file is the CLI arguments to be passed.
  The remaining lines are fed to `multi-grep` on stdin.

- `$my_test_name.exp`: the expected output of the test

  The test harness will capture all actual output on stdout and stderr when
  comparing against the `.exp` file.

To write a new test, create both of the above files. Alternatively, create only
the `.in` file, and run `./run-tests.sh --update` on your newly created file.

Feel free to create files in `tests/fixtures/` containing sample content to
search through within the individual tests. Also feel free to share fixtures
across tests.


### Bumping the version

- Update the version in `options.sml`
- Update the failing tests (`run-tests.sh --update`)
- Commit the changes, and create a new git tag with that version
- Make a new release on GitHub (`hub release`)
- Update the Homebrew formula


## TODO

- grep flags:
  - `-F --fixed-strings` (Don't parse pattern as a regular expression)
  - `-w --word-regexp` (Wrap pattern with word boundary pattern)
  - `-q --quiet` (Suppress normal output. Exit 0: match found; Exit 2: no matches)

- Can use record to wrap up context, store a ref in each record cell.

## Another example

Here's another short example. Given a Ruby file like this:

```ruby
# -- foo.rb --
class A
  sig {returns(BasicObject)}
  def initialize; end
end

class B
  sig {returns(BasicObject)}
  def another_method; end
end

class C
  sig {void}
  def void_method; end
end
```

We want to find all method signatures that say `returns(BasicObject)` for
methods named `initialize`. Naive `grep` won't work, because we can't match
across multiple lines. Instead, we can:

```shell
# print all lines matching returns.BasicObject:
❯ grep -nH returns.BasicObject foo.rb
foo.rb:3:  sig {returns(BasicObject)}
foo.rb:8:  sig {returns(BasicObject)}

# use AWK to print just the locations, and add +1 to the line number:
❯ ... | awk 'BEGIN { FS = ":"} {print $1 ":" ($2 + 1)}'
foo.rb:4
foo.rb:9

# use multi-grep to search for initialize:
❯ ... | ... | multi-grep initialize
foo.rb:4

# use AWK to subtract 1 to get the original line numbers:
❯ ... | ... | ... | awk 'BEGIN { FS = ":"} {print $1 ":" ($2 - 1)}'
foo.rb:3
```

## License

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://jez.io/MIT-LICENSE.txt)


[Symbol]: https://github.com/jez/symbol
[SML/NJ]: https://www.smlnj.org
[MLton]: http://mlton.org
