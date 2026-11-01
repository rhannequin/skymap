# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 11, 1, 9))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
ephem = Astronoby::Ephem.load(
  File.expand_path("../spec/fixtures/de440s_2025_2030_excerpt.bsp", __dir__)
)

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::Ecliptic.new,
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 3),
  Skymap::Layers::Planets.new(ephem: ephem, magnitude_limit: 8, labels: true),
  Skymap::Layers::Moon.new(ephem: ephem),
  Skymap::Layers::Sun.new(ephem: ephem),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "solar_system.svg"), svg)
