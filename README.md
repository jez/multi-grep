# multi-grep

[![Buildmulti-grep Status](https://travis-ci.org/jez/.svg?branch=master)](https://travis-ci.org/jez/multi-grep)

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
❯ ... | ... | multigrep initialize
foo.rb:4

# use AWK to subtract 1 to get the original line numbers:
❯ ... | ... | ... | awk 'BEGIN { FS = ":"} {print $1 ":" ($2 - 1)}'
foo.rb:3
```

So basically, if `grep` is like a chainsaw, `multi-grep` is more like a scalpel.

## Install


### macOS

### Linux

### From source


## Quickstart


## Contributing

Be sure to clone with `--recursive`.

### TODO

- more tests (for edge cases)
- audit grep / git grep / ag flags and see if there are any worth implementing
  - `-F --fixed-strings` (Don't parse pattern as a regular expression)
  - `-i --ignore-case` (Match case insensitively)
  - `-s --case-sensitive` (Match case sensitively)
  - `-v --invert-match` (Print lines that don't match pattern)
  - `-w --word-regexp` (Wrap pattern with word boundary pattern)
  - `-q --quiet` (Suppress normal output. Exit 0: match found; Exit 2: no matches)
- Documentation
- Check that release uploading works
  - macOS
  - Linux
- Homebrew formula

- Can use record to wrap up context, store a ref in each record cell.

## License

TODO(jez) MIT License
