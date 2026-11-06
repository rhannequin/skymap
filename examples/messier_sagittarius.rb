# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new
view = Skymap::View.new(
  center: Astronoby::Coordinates::Equatorial.new(
    right_ascension: Astronoby::Angle.from_hms(18, 20, 0),
    declination: Astronoby::Angle.from_degrees(-23),
    epoch: Astronoby::JulianDate::J2000
  ),
  field_of_view: Astronoby::Angle.from_degrees(30),
  orientation: :equatorial
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  view: view
)
svg = chart.render(
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 6),
  Skymap::Layers::DeepSkyObjects.new(
    objects: Skymap::Catalog::DeepSkyObjects.new,
    labels: true
  ),
  Skymap::Layers::Scale.new
)

File.write(File.join(__dir__, "messier_sagittarius.svg"), svg)
