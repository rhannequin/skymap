# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 4, 15, 21))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new
galaxies = Skymap::Catalog::DeepSkyObjects.new.select do |object|
  object.type == :galaxy
end
view = Skymap::View.new(
  center: Astronoby::Coordinates::Equatorial.new(
    right_ascension: Astronoby::Angle.from_hms(12, 27, 0),
    declination: Astronoby::Angle.from_degrees(12.7),
    epoch: Astronoby::JulianDate::J2000
  ),
  field_of_view: Astronoby::Angle.from_degrees(10),
  orientation: :equatorial
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  view: view
)
svg = chart.render(
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 8),
  Skymap::Layers::DeepSkyObjects.new(objects: galaxies, labels: true),
  Skymap::Layers::Scale.new
)

File.write(File.join(__dir__, "deep_sky.svg"), svg)
