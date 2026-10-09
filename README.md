# Skymap

[![CI](https://github.com/rhannequin/skymap/actions/workflows/ci.yml/badge.svg)](https://github.com/rhannequin/skymap/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/skymap.svg)](https://rubygems.org/gems/skymap)

Skymap is a Ruby library for generating maps of the sky.

<p align="center">
  <img
    src="https://raw.githubusercontent.com/rhannequin/skymap/main/sky_map.svg"
    width="480"
    alt="The sky over Paris on September 24, 2026 at 22:00 UTC, with the stars, the constellation lines and the constellation boundaries"
  >
</p>

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
stars = Skymap::Catalog::Stars.new.to_a

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::ConstellationBoundaries.new(
    boundaries: Skymap::Catalog::ConstellationBoundaries.new
  ),
  Skymap::Layers::ConstellationLines.new(
    lines: Skymap::Catalog::ConstellationLines.new,
    stars: stars
  ),
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::CardinalDirections.new
)

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
SVG.

### Layers

A map is the sky, with the layers given to `Chart#render` drawn on top of it,
in order: each layer is drawn over the previous ones. Without layers,
`Chart#render` draws an empty sky. Leave a layer out to hide what it draws.

#### Stars

`Skymap::Layers::Stars` draws stars, bigger the brighter they are.
`Skymap::Catalog::Stars` gives the 9,096 stars of the Yale Bright Star
Catalogue (see [Data sources](#data-sources)), but the layer accepts any list
of `Skymap::Star`.

By default, only stars of magnitude 5 or brighter are drawn, which is about
what you can see from a suburban sky. Use `magnitude_limit:` to draw more or
fewer stars:

```ruby
Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 6)
```

#### Constellation boundaries

`Skymap::Layers::ConstellationBoundaries` draws the boundaries between the
constellations as thin dashed lines, and stops the ones that cross the horizon
at the edge of the sky. `Skymap::Catalog::ConstellationBoundaries` gives the
borders of the 88 IAU constellations (see [Data sources](#data-sources)).

Layers are drawn in the order they are given: put the boundaries first to draw
them below the lines and the stars.

#### Constellation lines

`Skymap::Layers::ConstellationLines` draws the lines of the constellations.
`Skymap::Catalog::ConstellationLines` gives the lines of the 88 IAU
constellations (see [Data sources](#data-sources)).

Figures are drawn whole, even when some of their stars are fainter than the
magnitude limit of the stars layer, and lines that cross the horizon stop at
the edge of the sky. The stars given to the layer must include the stars of
the lines: lines to a star that is not given are left out.

Each line has a weight, as drawn on the IAU charts: `bold` for the best-known
shapes (the asterisms, such as the Big Dipper or the Teapot of Sagittarius),
`normal` for the rest of the figures and `thin` for the secondary lines. The
layer draws the lines it's given, so select the ones you want, for example
only the asterisms:

```ruby
asterisms = Skymap::Catalog::ConstellationLines.new.select do |line|
  line.weight == :bold
end

Skymap::Layers::ConstellationLines.new(lines: asterisms, stars: stars)
```

#### Cardinal directions

`Skymap::Layers::CardinalDirections` labels the cardinal directions (N, E, S,
W) in the padding, with a size that follows it: a padding of about 3% of the
size gives readable labels.

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

### Constellations

`data/constellations/iau/lines.csv` holds the lines of the 88 IAU
constellations (Mensa and Microscopium have none), one row per segment:

- `constellation`: the IAU abbreviation of the constellation.
- `from_hr`, `to_hr`: the ends of the segment, as HR numbers of stars of
  `data/stars.csv`. An end with two HR numbers, such as `5190 5193`, is the
  midpoint of these two stars: the IAU charts draw some lines to a pair of
  close stars rather than to one of them.
- `weight`: `bold` for the lines the charts draw thickest, the best-known
  shapes such as the Big Dipper or the Teapot of Sagittarius, `normal` for the
  rest of the main figures, `thin` for the secondary lines.

The lines are transcribed from the [IAU constellation maps][oae-maps] of the
IAU Office of Astronomy for Education, adapted from the original charts by
the IAU and Sky & Telescope magazine (Roger Sinnott & Rick Fienberg), with the
constellation patterns of Alan MacRobert, and released under the [Creative
Commons Attribution 4.0 International][cc-by-4] license.

The file was transcribed once from the vector PDF of each map, by matching the
ends of the lines drawn on the maps to the stars of the catalog, and checked
against the maps. It is not regenerated by a script.

### Constellation boundaries

`data/constellations/iau/boundaries.csv` holds the borders between the 88 IAU
constellations, one row per point of a border, in order:

- `border`: the number of the border. Each border between two constellations
  is listed once.
- `constellations`: the IAU abbreviations of the two constellations the border
  separates.
- `right_ascension` (hours) and `declination` (degrees): the coordinates of
  the point, in J2000. The borders of the constellations are straight lines of
  right ascension and declination in B1875, and curves in J2000: there is a
  point about every degree to follow them.

The borders come from the [Catalogue of Constellation Boundary Data][vi49] by
Davenhall and Leggett (VizieR VI/49), in the version of Bill J. Gray that
lists the constellation on each side of a border. They are the boundaries
defined by Delporte in 1930, in B1875 coordinates.

> Davenhall, A. C., Leggett, S. K., 1989, _Catalogue of Constellation Boundary
> Data_, Royal Observatory Edinburgh.

The file is generated with `bin/build_boundaries`, which downloads the
catalog from CDS, keeps each shared border once, adds the points along the
borders and precesses them to J2000 with Astronoby.

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
[oae-maps]: https://www.astro4edu.org/
[vi49]: https://cdsarc.cds.unistra.fr/viz-bin/cat/VI/49
[cc-by-4]: https://creativecommons.org/licenses/by/4.0/
