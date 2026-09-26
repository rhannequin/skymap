# frozen_string_literal: true

RSpec.describe Skymap::Chart do
  describe "#render" do
    it "renders the sky on the given canvas" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 1000, padding: 1.5)
      )

      svg = chart.render([])
      root = REXML::Document.new(svg).root

      expect(root["viewBox"]).to eq("0 0 1000 1000")
    end

    it "draws a star that never sets" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      circumpolar_star = equatorial(right_ascension: 0, declination: 89)

      svg = chart.render([circumpolar_star])
      _sky, *stars = circles_in(svg)

      expect(stars.size).to eq(1)
    end

    it "leaves out a star that never rises" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      never_rising_star = equatorial(right_ascension: 0, declination: -89)

      svg = chart.render([never_rising_star])
      _sky, *stars = circles_in(svg)

      expect(stars).to be_empty
    end
  end

  def observer_at(latitude:)
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(latitude),
      longitude: Astronoby::Angle.zero
    )
  end

  def equatorial(right_ascension:, declination:)
    Astronoby::Coordinates::Equatorial.new(
      right_ascension: Astronoby::Angle.from_hours(right_ascension),
      declination: Astronoby::Angle.from_degrees(declination),
      epoch: Astronoby::JulianDate::J2000
    )
  end
end
