# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(28.76),
  longitude: Astronoby::Angle.from_degrees(-17.89)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 8, 12, 23))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 6),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "naked_eye.svg"), svg)
