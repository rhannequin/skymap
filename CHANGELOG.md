# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/rhannequin/skymap/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/rhannequin/skymap/releases/tag/v0.0.1
[Astronoby]: https://github.com/rhannequin/astronoby
