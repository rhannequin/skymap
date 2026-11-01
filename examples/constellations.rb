# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 1, 15, 21))
canvas = Skymap::Canvas.new(size: 1000, padding: 30)
stars = Skymap::Catalog::Stars.new.to_a
lines = Skymap::Catalog::ConstellationLines.new.to_a

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  theme: Skymap::Theme.light
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

File.write(File.join(__dir__, "constellations.svg"), svg)
