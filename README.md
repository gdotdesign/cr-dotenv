# Dotenv

[![Build Status](https://travis-ci.org/gdotdesign/cr-dotenv.svg?branch=master)](https://travis-ci.org/gdotdesign/cr-dotenv)

Loads `.env` file.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  dotenv:
    github: gdotdesign/cr-dotenv
```

## Usage

### Dotenv file example

```
# Comments can be included for context
#
MY_VARIABLE=my-value

# Empty Lines are also ignored
#
ANOTHER_VAR=awesome-value
```

### Basic example

To load a file named `.env-file`:

```crystal
require "dotenv"

# The default file is ".env"
Dotenv.load ".env-file"
```

See the API docs for more examples.

## Contributing

1. Fork it ( https://github.com/gdotdesign/cr-dotenv/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[gdotdesign]](https://github.com/[gdotdesign]) Gusztáv Szikszai - creator, maintainer
- [[bonyiii]](https://github.com/[bonyiii])
- [[kriskova]](https://github.com/kriskova)
- [[neovintage]](https://github.com/[neovintage]) Rimas Silkaitis
- [[rodrigopinto]](https://github.com/[rodrigopinto]) Rodrigo Pinto
