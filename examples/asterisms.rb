# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 7, 20, 22))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
asterisms = Skymap::Catalog::ConstellationLines.new.select do |line|
  line.weight == :bold
end

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::ConstellationLines.new(lines: asterisms, stars: stars),
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 4),
  Skymap::Layers::StarNames.new(stars: stars, stars_magnitude_limit: 4),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "asterisms.svg"), svg)
