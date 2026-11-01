# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-11-01

### Added

- `Skymap::Layers::Ecliptic` draws the ecliptic, the line the Sun follows in
  the sky, stopping at the horizon
- `Skymap::Layers::Planets` draws the planets, from Mercury to Neptune, sized
  by their magnitude, down to a `magnitude_limit:` (5 by default), from an
  ephemeris given with `ephem:`, and writes their names with `labels: true`
  or the names given with `names:`
- `Skymap::Layers::Sun` draws the Sun where it is in the sky, from an ephemeris
  given with `ephem:`
- `Skymap::Layers::ConstellationNames` writes the name of each constellation in
  the middle of its stars, from `Skymap::Catalog::ConstellationNames` or the
  names given with `names:`
- `Skymap::Catalog::ConstellationNames` gives the English name of each of the
  88 IAU constellations

### Changed

- `Skymap::Canvas` raises an `ArgumentError` when the padding is negative or
  leaves no room for the sky
- Rendering is about 20 times faster: the precession, nutation and sidereal
  time are computed once per chart instead of once per point, using
  `Astronoby::HorizontalTransformation`
- Skymap requires Astronoby 0.11 or later

### Fixed

- The catalogs give an enumerator when `each` is called without a block,
  instead of raising a `LocalJumpError`

## [0.2.0] - 2026-10-27

### Added

- `Skymap::Layers::ConstellationBoundaries` draws the boundaries between the
  constellations as thin dashed lines, stopping at the horizon
- `Skymap::Catalog::ConstellationBoundaries` gives the borders of the 88 IAU
  constellations, in J2000 coordinates
- `Skymap::Layers::Moon` draws the Moon with its phase, where it is in the sky,
  from an ephemeris given with `ephem:`

### Changed

- The data of the constellations lives in `data/constellations/iau/`:
  `data/constellations/iau.csv` is now `data/constellations/iau/lines.csv`

## [0.1.0] - 2026-10-05

### Added

- `Skymap::Chart` draws the sky seen by an [Astronoby] observer at a given
  instant and returns it as an SVG string, using a stereographic projection
  with the zenith at the center and the horizon at the edge
- `Skymap::Canvas` sets the size of the SVG and the padding around the horizon
- `Chart#render` takes layers, drawn in order on top of the sky
- `Skymap::Layers::Stars` draws stars sized by their magnitude and scaled with
  the canvas, down to a `magnitude_limit:` (5 by default)
- `Skymap::Catalog::Stars` gives the 9,096 stars of the Yale Bright Star
  Catalogue
- `Skymap::Layers::ConstellationLines` draws the lines of the constellations,
  stopping at the horizon
- `Skymap::Catalog::ConstellationLines` gives the lines of the 88 IAU
  constellations, each with a `bold`, `normal` or `thin` weight
- `Skymap::Layers::CardinalDirections` labels the cardinal directions around
  the horizon

## [0.0.1] - 2026-09-25

- Initial release to reserve the gem name on RubyGems.org

[Unreleased]: https://github.com/rhannequin/skymap/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/rhannequin/skymap/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/rhannequin/skymap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rhannequin/skymap/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/rhannequin/skymap/releases/tag/v0.0.1
[Astronoby]: https://github.com/rhannequin/astronoby
