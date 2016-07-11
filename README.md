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

Your `.env` file:
```
MY_VARIABLE=my-value
```

In your application:
```crystal
require "dotenv"

# Load deafult ".env" file
Dotenv.load

# Other file
Dotenv.load ".env-other"

# From IO
Dotenv.load MemoryIO.new("VAR=test")

# From Hash
Dotenv.load({"VAR" => "test"})

# A Hash is returned with the loaded variables
hash = Dotenv.load

puts hash["MY_VARIABLE"] # my-value
puts ENV["MY_VARIABLE"] # my-value
```

## Contributing

1. Fork it ( https://github.com/gdotdesign/cr-dotenv/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[gdotdesign]](https://github.com/[gdotdesign]) Gusztáv Szikszai - creator, maintainer
