# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(-33.8688),
  longitude: Astronoby::Angle.from_degrees(151.2093)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 6, 21, 10))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
lines = Skymap::Catalog::ConstellationLines.new.to_a

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::ConstellationLines.new(lines: lines, stars: stars),
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::StarNames.new(stars: stars, magnitude_limit: 1),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "southern_sky.svg"), svg)
