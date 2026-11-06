# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `data/stars.csv` and `Skymap::Catalog::Stars` give the proper motion, the
  parallax and the radial velocity of the stars, from the Yale Bright Star
  Catalogue, and `Skymap::Star` takes the optional `proper_motion_ra:`,
  `proper_motion_dec:` (`Astronoby::AngularVelocity`), `parallax:`
  (`Astronoby::Angle`) and `radial_velocity:` (`Astronoby::Velocity`)
- `Skymap::Star#coordinates_at` gives the equatorial coordinates of a star at an
  `Astronoby::Instant`, with its proper motion applied, as
  `Astronoby::Coordinates::Equatorial` at J2000. A star with a proper motion
  must have coordinates at J2000, or `Skymap::Star` raises an `ArgumentError`
- `Skymap::Context#possibly_visible?` tells whether a star can be drawn on the
  chart, above the horizon and in the view, without applying its proper motion,
  so that the layers of stars skip the stars far from a zoomed view
- `Skymap::View` zooms the map on an area of the sky, given by the equatorial
  or horizontal coordinates of its center and a field of view as an
  `Astronoby::Angle`, with `view:` on `Skymap::Chart`, with the horizon drawn as
  a line when it is in the view, and the Sun and the Moon at their size in the
  sky when it is larger than their usual size on the map
- `Skymap::View` takes `orientation:` (`:zenith_up` by default, or `:equatorial`
  to put the north celestial pole at the top), `rotation:` as an
  `Astronoby::Angle` and `mirrored:` to give the map the orientation of a
  telescope
- `Skymap::Layers::Grid` draws the celestial coordinate grid, the lines of
  right ascension and the circles of declination, every `step:` angle (30
  degrees by default), stopping at the horizon
- `epoch: :of_date` on `Skymap::Layers::Grid` draws the grid in the true
  equator and equinox of the date of the chart, centered on the true celestial
  pole, instead of J2000 (the default)
- `Skymap::Layers::Scale` draws a scale bar with a round angular length, such
  as `30′`, in the lower left of a map with a view
- `print_size:` on `Skymap::Canvas`, with `Skymap::PrintSize`, writes the SVG at
  a physical size in millimeters, centimeters or inches, for example the
  width of an A4 sheet with `Skymap::PrintSize.paper(:a4)`
- `Skymap::Layers::FieldCircles` draws circles of given true fields around the
  center of the view or a point of your choice, with their labels, to show what
  a finder scope or an eyepiece covers
- `Skymap::Telescope`, `Skymap::Eyepiece` and `Skymap::Setup` describe the
  equipment and compute the magnification, the true field as an
  `Astronoby::Angle` and a label such as `25 mm, 48×, 1.1°`, and
  `Skymap::Field` is a named field, such as a finder scope or a Telrad ring
- `Skymap::Theme` has optional colors, which fall back to the color of another
  one when they are not given, so that a theme built with `Skymap::Theme.new`
  for an earlier version keeps working: `grid` falls back to `boundary`,
  `scale` to `star_name` and `field_circle` to `planet`

### Changed

- The lit side of `Skymap::Layers::Moon` faces the Sun on the map, wherever
  the Moon is and in every orientation of the view, instead of being drawn as
  the observer sees it from the ground
- Equatorial coordinates given to `Skymap::Context#horizontal_coordinates`, and
  as the center of a `Skymap::View`, can be at J2000 or at the date of the
  chart, and any other epoch now raises an `ArgumentError` (it was an
  `Astronoby::IncompatibleArgumentsError`)
- Stars are drawn at their position at the date of the chart, with their proper
  motion applied from J2000, instead of at their catalog position: the positions
  of stars in existing charts change, visibly only in charts with a field of
  view under a degree. A star without a proper motion does not move

## [0.4.0] - 2026-11-05

### Added

- `Skymap::Theme` gives the colors and the font of the map, with the
  `Skymap::Theme.dark` (default), `Skymap::Theme.light` and
  `Skymap::Theme.night` themes, and is given to `Skymap::Chart` with `theme:`
- `Skymap::Layers::StarNames` writes the names of the brightest stars, down to
  a `magnitude_limit:` (2 by default), from `Skymap::Catalog::StarNames` or the
  names given with `names:`, and placed for the stars drawn down to
  `stars_magnitude_limit:` (5 by default)
- `Skymap::Catalog::StarNames` gives the IAU name of 333 stars of the Bright
  Star Catalogue, such as Sirius or Betelgeuse

### Changed

- The names of the planets next to the horizon move towards the center of the
  map until they fit in the sky

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

[Unreleased]: https://github.com/rhannequin/skymap/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/rhannequin/skymap/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/rhannequin/skymap/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/rhannequin/skymap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rhannequin/skymap/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/rhannequin/skymap/releases/tag/v0.0.1
[Astronoby]: https://github.com/rhannequin/astronoby
