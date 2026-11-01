# frozen_string_literal: true

require "skymap"

observer = Astronoby::Observer.new(
  latitude: Astronoby::Angle.from_degrees(48.8575),
  longitude: Astronoby::Angle.from_degrees(2.3514)
)
instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 23, 19))
canvas = Skymap::Canvas.new(size: 800, padding: 24)
stars = Skymap::Catalog::Stars.new.to_a
names = {
  "Ari" => "Bélier",
  "Tau" => "Taureau",
  "Gem" => "Gémeaux",
  "Cnc" => "Cancer",
  "Leo" => "Lion",
  "Vir" => "Vierge",
  "Lib" => "Balance",
  "Sco" => "Scorpion",
  "Sgr" => "Sagittaire",
  "Cap" => "Capricorne",
  "Aqr" => "Verseau",
  "Psc" => "Poissons"
}
zodiac = Skymap::Catalog::ConstellationLines.new.select do |line|
  names.key?(line.constellation)
end

chart = Skymap::Chart.new(observer: observer, instant: instant, canvas: canvas)
svg = chart.render(
  Skymap::Layers::Ecliptic.new,
  Skymap::Layers::ConstellationLines.new(lines: zodiac, stars: stars),
  Skymap::Layers::Stars.new(stars: stars),
  Skymap::Layers::ConstellationNames.new(
    lines: zodiac,
    stars: stars,
    names: names
  ),
  Skymap::Layers::CardinalDirections.new
)

File.write(File.join(__dir__, "zodiac.svg"), svg)
