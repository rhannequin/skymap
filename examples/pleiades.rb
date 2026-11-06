# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 12, 14, 21))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new
view = Skymap::View.new(
  center: Astronoby::Coordinates::Equatorial.new(
    right_ascension: Astronoby::Angle.from_hms(3, 47, 0),
    declination: Astronoby::Angle.from_dms(24, 7, 0),
    epoch: Astronoby::JulianDate::J2000
  ),
  field_of_view: Astronoby::Angle.from_degrees(4),
  orientation: :equatorial,
  rotation: Astronoby::Angle.from_degrees(180)
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  view: view
)
svg = chart.render(
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 7),
  Skymap::Layers::StarNames.new(
    stars: stars,
    magnitude_limit: 6,
    stars_magnitude_limit: 7
  )
)

File.write(File.join(__dir__, "pleiades.svg"), svg)
