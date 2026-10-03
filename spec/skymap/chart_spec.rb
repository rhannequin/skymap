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

    it "draws a line between two stars, from one dot to the other" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)
      second = star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)

      svg = chart.render([first, second], lines: [line(from: [1], to: [2])])
      _sky, first_dot, second_dot = circles_in(svg)
      drawn = lines_in(svg).first

      expect(drawn["x1"]).to eq(first_dot["cx"])
      expect(drawn["y1"]).to eq(first_dot["cy"])
      expect(drawn["x2"]).to eq(second_dot["cx"])
      expect(drawn["y2"]).to eq(second_dot["cy"])
    end

    it "draws whole figures, including stars fainter than the limit" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      bright = star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)
      faint = star(hr: 2, right_ascension: 6, declination: 80, magnitude: 6)

      svg = chart.render([bright, faint], lines: [line(from: [1], to: [2])])
      _sky, *stars = circles_in(svg)

      expect(stars.size).to eq(1)
      expect(lines_in(svg).size).to eq(1)
    end

    it "leaves out a line below the horizon" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(hr: 1, right_ascension: 0, declination: -80, magnitude: 2)
      second = star(hr: 2, right_ascension: 6, declination: -80, magnitude: 2)

      svg = chart.render([first, second], lines: [line(from: [1], to: [2])])

      expect(lines_in(svg)).to be_empty
    end

    it "stops a line that goes below the horizon at the horizon" do
      chart = described_class.new(
        observer: observer_at(latitude: 90),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      above = star(hr: 1, right_ascension: 3, declination: 30, magnitude: 2)
      below = star(hr: 2, right_ascension: 3, declination: -20, magnitude: 2)

      svg = chart.render([above, below], lines: [line(from: [1], to: [2])])
      _sky, dot = circles_in(svg)
      drawn = lines_in(svg).first
      dot_x, dot_y = Float(dot["cx"]) - 200, Float(dot["cy"]) - 200
      end_x, end_y = Float(drawn["x2"]) - 200, Float(drawn["y2"]) - 200

      expect(Math.hypot(end_x, end_y).round(1)).to eq(198.5)
      expect(Math.atan2(end_y, end_x).round(2))
        .to eq(Math.atan2(dot_y, dot_x).round(2))
    end

    it "draws a line ending between two stars to their midpoint" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)
      second = star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)
      third = star(hr: 3, right_ascension: 12, declination: 80, magnitude: 2)

      svg = chart.render(
        [first, second, third],
        lines: [line(from: [1], to: [2, 3])]
      )
      _sky, _first, second_dot, third_dot = circles_in(svg)
      drawn = lines_in(svg).first

      expect(Float(drawn["x2"])).to be_within(0.01).of(
        (Float(second_dot["cx"]) + Float(third_dot["cx"])) / 2
      )
      expect(Float(drawn["y2"])).to be_within(0.01).of(
        (Float(second_dot["cy"]) + Float(third_dot["cy"])) / 2
      )
    end

    it "draws bold lines thicker than thin ones" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)
      second = star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)
      lines = [
        line(from: [1], to: [2], weight: :bold),
        line(from: [1], to: [2], weight: :thin)
      ]

      svg = chart.render([first, second], lines: lines)
      bold, thin = lines_in(svg)

      expect(Float(bold["stroke-width"])).to be > Float(thin["stroke-width"])
    end

    it "leaves out a line to a star that was not given" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)

      svg = chart.render([first], lines: [line(from: [1], to: [2])])

      expect(lines_in(svg)).to be_empty
    end
  end

  def line(from:, to:, weight: :normal)
    Skymap::ConstellationLine.new(
      constellation: "UMi",
      from: from,
      to: to,
      weight: weight
    )
  end

  def observer_at(latitude:)
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(latitude),
      longitude: Astronoby::Angle.zero
    )
  end

  def star(right_ascension:, declination:, magnitude:, hr: nil)
    Skymap::Star.new(
      hr: hr,
      equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(right_ascension),
        declination: Astronoby::Angle.from_degrees(declination),
        epoch: Astronoby::JulianDate::J2000
      ),
      magnitude: magnitude
    )
  end
end
