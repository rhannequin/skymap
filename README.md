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

Skymap draws the sky seen by an observer at a given instant, and returns it
as an SVG string:

```ruby
require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
canvas = Skymap::Canvas.new(size: 800, padding: 24)

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(Skymap::Catalog::Stars.new)

File.write("sky_map.svg", svg)
```

The observer and the instant are [Astronoby] objects. Astronoby computes where
each star is in the sky and Skymap draws it.

The map is a disk: the zenith is at the center and the horizon is the edge. It
uses a [stereographic projection], the most common one for sky charts because
it keeps the shapes of constellations, even near the horizon. North is at the
top and East is on the left, as on a map you would hold above your head.

### Canvas

The canvas is the square SVG the map is drawn on. `size` is its width and
height, and `padding` is the space between the horizon and the edge of the
SVG. The cardinal directions (N, E, S, W) are drawn in the padding.

### Stars

`Skymap::Catalog::Stars` gives the 9,096 stars of the Yale Bright Star
Catalogue (see [Data sources](#data-sources)), but `Chart#render` accepts any
list of `Skymap::Star`.

Stars are drawn bigger the brighter they are. By default, only stars of
magnitude 5 or brighter are drawn, which is about what you can see from a
suburban sky. Use `magnitude_limit:` to draw more or fewer stars:

```ruby
Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  magnitude_limit: 6
)
```

## Data sources

### Stars

`data/stars.csv` is extracted from the [Yale Bright Star Catalogue, 5th
Revised Edition][bsc5] (VizieR V/50): the 9,096 stars of the catalog with
their Harvard Revised number (`hr`), J2000 coordinates (`right_ascension` in
hours, `declination` in degrees) and visual magnitude (`magnitude`). The 14
non-stellar entries kept only for numbering are left out.

> Hoffleit, D., Warren Jr., W. H., 1991, _The Bright Star Catalogue, 5th
> Revised Ed. (Preliminary Version)_, Astronomical Data Center, NSSDC/ADC.

The file is generated with `bin/build_catalog`, which downloads the catalog
from CDS.

This research has made use of the VizieR catalogue access tool, CDS,
Strasbourg, France ([DOI: 10.26093/cds/vizier][vizier-doi]). The original
description of the VizieR service was published in 2000, A&AS 143, 23.

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

[Astronoby]: https://github.com/rhannequin/astronoby
[stereographic projection]: https://en.wikipedia.org/wiki/Stereographic_map_projection
[Standard Ruby]: https://github.com/standardrb/standard
[trusted publishing]: https://guides.rubygems.org/trusted-publishing/
[MIT License]: https://opensource.org/licenses/MIT
[bsc5]: https://cdsarc.cds.unistra.fr/viz-bin/cat/V/50
[vizier-doi]: https://doi.org/10.26093/cds/vizier
