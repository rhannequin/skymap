# frozen_string_literal: true

RSpec.describe Skymap::Projection::Stereographic do
  describe "#project" do
    it "projects the zenith to the center" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(90), azimuth: degrees(123))

      expect(x.round(2)).to eq(200)
      expect(y.round(2)).to eq(200)
    end

    it "projects the northern horizon to the top edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(0), azimuth: degrees(0))

      expect(x.round(2)).to eq(200)
      expect(y.round(2)).to eq(1.5)
    end

    it "projects the eastern horizon to the left edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(0), azimuth: degrees(90))

      expect(x.round(2)).to eq(1.5)
      expect(y.round(2)).to eq(200)
    end

    it "projects the southern horizon to the bottom edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(0), azimuth: degrees(180))

      expect(x.round(2)).to eq(200)
      expect(y.round(2)).to eq(398.5)
    end

    it "projects the western horizon to the right edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(0), azimuth: degrees(270))

      expect(x.round(2)).to eq(398.5)
      expect(y.round(2)).to eq(200)
    end

    it "projects the northeastern horizon to the top-left edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(0), azimuth: degrees(45))

      expect(x.round(2)).to eq(59.64)
      expect(y.round(2)).to eq(59.64)
    end

    it "projects 45° of altitude closer to the center than to the edge" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(45), azimuth: degrees(0))

      expect(x.round(2)).to eq(200)
      expect(y.round(2)).to eq(117.78)
    end

    it "projects points below the horizon outside the disk" do
      projection = described_class.new(
        center_x: 200,
        center_y: 200,
        radius: 198.5
      )

      x, y = projection.project(altitude: degrees(-10), azimuth: degrees(0))

      expect(x.round(2)).to eq(200)
      expect(y.round(2)).to eq(-36.56)
    end
  end

  def degrees(value)
    Astronoby::Angle.from_degrees(value)
  end
end
