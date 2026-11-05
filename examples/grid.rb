# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(69.6492),
  longitude: Astronoby::Angle.from_degrees(18.9553)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 12, 21, 20))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
lines = Skymap::Catalog::ConstellationLines.new.to_a
theme = Skymap::Theme.dark.with(grid: "#3b5273")

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  theme: theme
)
svg = chart.render(
  Skymap::Layers::Grid.new(step: 15),
  Skymap::Layers::Ecliptic.new,
  Skymap::Layers::ConstellationLines.new(lines: lines, stars: stars),
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "grid.svg"), svg)
