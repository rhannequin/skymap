# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2027, 1, 15, 21))
canvas = Skymap::Canvas.new(
  size: 800,
  padding: 24,
  print_size: Skymap::PrintSize.paper(:a4)
)
stars = Skymap::Catalog::Stars.new.to_a
view = Skymap::View.new(
  center: Astronoby::Coordinates::Equatorial.new(
    right_ascension: Astronoby::Angle.from_hours(3.79),
    declination: Astronoby::Angle.from_degrees(24.1),
    epoch: Astronoby::JulianDate::J2000
  ),
  field_of_view: 4
)

chart = Skymap::Chart.new(
  observer: observer,
  instant: instant,
  canvas: canvas,
  theme: Skymap::Theme.light,
  view: view
)
svg = chart.render(
  Skymap::Layers::Grid.new(step: 1),
  Skymap::Layers::Stars.new(stars: stars, magnitude_limit: 7),
  Skymap::Layers::StarNames.new(stars: stars, magnitude_limit: 4),
  Skymap::Layers::Scale.new
)

File.write(File.join(__dir__, "finder_chart.svg"), svg)
