# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(35.6762),
  longitude: Astronoby::Angle.from_degrees(139.6503)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 12, 14, 13))
canvas = Skymap::Canvas.new(size: 1000, padding: 30)
stars = Skymap::Catalog::Stars.new.to_a
lines = Skymap::Catalog::ConstellationLines.new.to_a
theme = Skymap::Theme.dark.with(
  background: "#0b3d91",
  sky: "#0b3d91",
  horizon: "#ffffff",
  star: "#ffffff",
  constellation_line: "#bcd2ff",
  boundary: "#6f95e0",
  constellation_name: "#ffffff",
  label: "#ffffff"
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  theme: theme
)
svg = chart.render(
  Skymap::Layers::ConstellationBoundaries.new(
    boundaries: Skymap::Catalog::ConstellationBoundaries.new
  ),
  Skymap::Layers::ConstellationLines.new(lines: lines, stars: stars),
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::ConstellationNames.new(lines: lines, stars: stars),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "blueprint.svg"), svg)
