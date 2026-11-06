# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 1, 15, 21))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new
lines = Skymap::Catalog::ConstellationLines.new.to_a
view = Skymap::View.new(
  center: Astronoby::Coordinates::Equatorial.new(
    right_ascension: Astronoby::Angle.from_hours(5.6),
    declination: Astronoby::Angle.zero,
    epoch: Astronoby::JulianDate::J2000
  ),
  field_of_view: Astronoby::Angle.from_degrees(50)
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  view: view
)
svg = chart.render(
  Skymap::Layers::ConstellationBoundaries.new(
    boundaries: Skymap::Catalog::ConstellationBoundaries.new
  ),
  Skymap::Layers::ConstellationLines.new(lines: lines, stars: stars),
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 6),
  Skymap::Layers::StarNames.new(stars: stars, magnitude_limit: 2.5),
  Skymap::Layers::ConstellationNames.new(lines: lines, stars: stars)
)

File.write(File.join(__dir__, "orion.svg"), svg)
