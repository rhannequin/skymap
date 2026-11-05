# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
telescope = Skymap::Telescope.new(focal_length_mm: 1200, aperture_mm: 200)
eyepiece = Skymap::Eyepiece.new(
  focal_length_mm: 25,
  apparent_field_of_view: Astronoby::Angle.from_degrees(52)
)
setup = Skymap::Setup.new(telescope: telescope, eyepiece: eyepiece)
finder = Skymap::Field.new(
  true_field: Astronoby::Angle.from_degrees(5),
  label: "Finder 5°"
)
target = Astronoby::Coordinates::Equatorial.new(
  right_ascension: Astronoby::Angle.from_hours(19.512),
  declination: Astronoby::Angle.from_degrees(27.96),
  epoch: Astronoby::JulianDate::J2000
)
view = Skymap::View.new(
  center: target,
  field_of_view: Astronoby::Angle.from_degrees(8)
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
    magnitude_limit: 4,
    stars_magnitude_limit: 7
  ),
  Skymap::Layers::FieldCircles.new(fields: [finder, setup], labels: true)
)

File.write(File.join(__dir__, "field_circles.svg"), svg)
