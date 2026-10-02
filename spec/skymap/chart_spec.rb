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
      circumpolar_star = star(right_ascension: 0, declination: 89, magnitude: 2)

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
      never_rising_star = star(
        right_ascension: 0,
        declination: -89,
        magnitude: 2
      )

      svg = chart.render([never_rising_star])
      _sky, *stars = circles_in(svg)

      expect(stars).to be_empty
    end

    it "leaves out stars fainter than magnitude 5 by default" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      visible_star = star(right_ascension: 0, declination: 89, magnitude: 5)
      faint_star = star(right_ascension: 12, declination: 89, magnitude: 5.1)

      svg = chart.render([visible_star, faint_star])
      _sky, *stars = circles_in(svg)

      expect(stars.size).to eq(1)
    end

    it "leaves out stars fainter than the given magnitude limit" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        magnitude_limit: 3
      )
      visible_star = star(right_ascension: 0, declination: 89, magnitude: 3)
      faint_star = star(right_ascension: 12, declination: 89, magnitude: 4)

      svg = chart.render([visible_star, faint_star])
      _sky, *stars = circles_in(svg)

      expect(stars.size).to eq(1)
    end

    it "draws brighter stars bigger" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      bright_star = star(right_ascension: 0, declination: 89, magnitude: 0)
      faint_star = star(right_ascension: 12, declination: 89, magnitude: 5)

      svg = chart.render([bright_star, faint_star])
      _sky, bright, faint = circles_in(svg)

      expect(Float(bright["r"])).to be > Float(faint["r"])
    end
    it "scales stars with the size of the sky" do
      small_chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large_chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      faint_star = star(right_ascension: 0, declination: 89, magnitude: 5)

      _sky, small = circles_in(small_chart.render([faint_star]))
      _sky, large = circles_in(large_chart.render([faint_star]))

      expect(small["r"]).to eq("0.5")
      expect(large["r"]).to eq("1.0")
    end
    it "labels the cardinal directions in the padding" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      svg = chart.render([])
      labels = texts_in(svg).map do |text|
        [text.text.strip, text["x"], text["y"]]
      end

      expect(labels).to contain_exactly(
        ["N", "200.0", "10.0"],
        ["E", "10.0", "200.0"],
        ["S", "200.0", "390.0"],
        ["W", "390.0", "200.0"]
      )
    end

    it "sizes the cardinal directions to fit in the padding" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      svg = chart.render([])
      sizes = texts_in(svg).map { |text| text["font-size"] }

      expect(sizes).to all(eq("12.0"))
    end
  end

  def observer_at(latitude:)
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(latitude),
      longitude: Astronoby::Angle.zero
    )
  end

  def star(right_ascension:, declination:, magnitude:)
    Skymap::Star.new(
      hr: nil,
      equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(right_ascension),
        declination: Astronoby::Angle.from_degrees(declination),
        epoch: Astronoby::JulianDate::J2000
      ),
      magnitude: magnitude
    )
  end
end
