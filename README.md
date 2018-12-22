# multi-grep

[![Buildmulti-grep Status](https://travis-ci.org/jez/multi-grep.svg?branch=master)](https://travis-ci.org/jez/multi-grep)

> Search for a pattern on specific lines

By default, `grep` searches for a given pattern on **all** lines in a file.
Sometimes that is too coarse grained. By contrast, `multi-grep` searches for a
pattern only on the specified lines. Here's a short example:

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

[→ View on sorbet.run](#TODO.jez)

Let's say we want to find all method signatures that say `returns(BasicObject)`
for methods named `initialize`. `grep` won't work, because we can't match across
multiple lines. Instead, we can:

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

So basically, if `grep` is like a chainsaw, `multi-grep` is more like a scalpel.
Using a combination of `grep`, `awk`, and `multi-grep`, we can list specifically
the file locations corresponding to method signatures for methods named
`initialize`.


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

## TODO

- grep flags:
  - `-F --fixed-strings` (Don't parse pattern as a regular expression)
  - `-w --word-regexp` (Wrap pattern with word boundary pattern)
  - `-q --quiet` (Suppress normal output. Exit 0: match found; Exit 2: no matches)
- Test and build release on Linux

- Can use record to wrap up context, store a ref in each record cell.

## License

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://jez.io/MIT-LICENSE.txt)

