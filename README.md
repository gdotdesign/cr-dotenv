# Dotenv

Loads `.env` file.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  cr-dotenv:
    github: gdotdesign/cr-dotenv
```


## Usage

```
MY_VARIABLE=my-value
```


```crystal
require "dotenv"

Dotenv.load

puts ENV["MY_VARIABLE"] # my-value
```

## Contributing

1. Fork it ( https://github.com/[your-github-name]/cr-dotenv/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[gdotdesign]](https://github.com/[gdotdesign]) Gusztáv Szikszai - creator, maintainer
