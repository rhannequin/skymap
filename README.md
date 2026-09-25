# Skymap

[![CI](https://github.com/rhannequin/skymap/actions/workflows/ci.yml/badge.svg)](https://github.com/rhannequin/skymap/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/skymap.svg)](https://rubygems.org/gems/skymap)

Skymap is a Ruby library for generating maps of the sky.

> [!WARNING]
> This project is in its very early stages, please expect breaking changes.

## Installation

Install the gem and add it to the application's Gemfile by executing:

```bash
bundle add skymap
```

If Bundler is not being used to manage dependencies, install the gem by
executing:

```bash
gem install skymap
```

## Usage

Coming soon.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rake` to run the tests and the linter. You can also run
`bin/console` for an interactive prompt that will allow you to experiment.

- Tests: `bundle exec rspec`
- Linter ([Standard Ruby] through RuboCop): `bundle exec rubocop`
  (`bundle exec rubocop -a` to autocorrect)
- Everything CI checks: `bin/ci`

### Releasing

1. Update the version number in `lib/skymap/version.rb` and `CHANGELOG.md`.
2. Commit, then tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. The [Release workflow](.github/workflows/release.yml) builds and publishes
   the gem to RubyGems.org using [trusted publishing].

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/rhannequin/skymap. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License].

## Code of Conduct

Everyone interacting in the Skymap project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](CODE_OF_CONDUCT.md).

[Standard Ruby]: https://github.com/standardrb/standard
[trusted publishing]: https://guides.rubygems.org/trusted-publishing/
[MIT License]: https://opensource.org/licenses/MIT
