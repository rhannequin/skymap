# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(39.74),
  longitude: Astronoby::Angle.from_degrees(-104.99)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 10, 18, 3))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
ephem = Astronoby::Ephem.load(
  ENV.fetch(
    "EPHEMERIS",
    File.expand_path("../spec/fixtures/de440s_2025_2030_excerpt.bsp", __dir__)
  )
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  theme: Skymap::Theme.night
)
svg = chart.render(
  Skymap::Layers::Ecliptic.new,
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::StarNames.new(stars: stars),
  Skymap::Layers::Planets.new(ephem: ephem, labels: true),
  Skymap::Layers::Moon.new(ephem: ephem),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "night_vision.svg"), svg)
