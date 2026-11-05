# frozen_string_literal: true

RSpec.describe Skymap::Projection::ObliqueStereographic do
  describe "#project" do
    it "projects the center of the view to the center of the canvas" do
      projection = southern_view(altitude: 30, field_of_view: 60)

      point = projection.project(altitude: degrees(30), azimuth: degrees(180))

      expect(point.x.round(2)).to eq(200)
      expect(point.y.round(2)).to eq(200)
    end

    it "projects the points at half the field of view to the edge" do
      projection = southern_view(altitude: 30, field_of_view: 60)

      above = projection.project(altitude: degrees(60), azimuth: degrees(180))
      below = projection.project(altitude: degrees(0), azimuth: degrees(180))

      expect([above.x.round(2), above.y.round(2)]).to eq([200, 1.5])
      expect([below.x.round(2), below.y.round(2)]).to eq([200, 398.5])
    end

    it "puts the east on the left and the west on the right" do
      projection = southern_view(altitude: 30, field_of_view: 60)

      east = projection.project(altitude: degrees(30), azimuth: degrees(150))
      west = projection.project(altitude: degrees(30), azimuth: degrees(210))

      expect(east.x).to be < 200
      expect(west.x).to be > 200
    end

    it "gives the same map as the full sky around the zenith" do
      full = Skymap::Projection::Stereographic.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5
      )
      zenith = southern_view(altitude: 90, field_of_view: 180)

      expected = full.project(altitude: degrees(35), azimuth: degrees(250))
      point = zenith.project(altitude: degrees(35), azimuth: degrees(250))

      expect(point.x).to be_within(1e-9).of(expected.x)
      expect(point.y).to be_within(1e-9).of(expected.y)
    end

    it "magnifies the sky when the field of view is smaller" do
      wide = southern_view(altitude: 30, field_of_view: 60)
      narrow = southern_view(altitude: 30, field_of_view: 30)

      from_wide = wide.project(altitude: degrees(40), azimuth: degrees(180))
      from_narrow = narrow.project(altitude: degrees(40), azimuth: degrees(180))

      expect(200 - from_narrow.y).to be > (200 - from_wide.y) * 1.9
    end

    it "gives a finite point opposite the center" do
      projection = southern_view(altitude: 30, field_of_view: 60)

      point = projection.project(altitude: degrees(-30), azimuth: degrees(0))

      expect(point.x).to be_finite
      expect(point.y).to be_finite
    end
  end

  def southern_view(altitude:, field_of_view:)
    described_class.new(
      center: Skymap::Point.new(x: 200, y: 200),
      radius: 198.5,
      altitude: degrees(altitude),
      azimuth: degrees(180),
      field_of_view: field_of_view
    )
  end

  def degrees(value)
    Astronoby::Angle.from_degrees(value)
  end
end
