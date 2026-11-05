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

  describe "#project with an equatorial orientation" do
    it "puts the direction of the pole at the top" do
      projection = looking_south(
        orientation: :equatorial,
        pole: [0.0, 1.0, 0.0]
      )

      towards_pole = projection.project(
        altitude: degrees(0),
        azimuth: degrees(90)
      )

      expect(towards_pole.x.round(2)).to eq(200)
      expect(towards_pole.y).to be < 200
    end

    it "does not put the zenith at the top any more" do
      projection = looking_south(
        orientation: :equatorial,
        pole: [0.0, 1.0, 0.0]
      )

      above = projection.project(altitude: degrees(10), azimuth: degrees(180))

      expect(above.y.round(2)).to eq(200)
      expect(above.x).not_to eq(200)
    end

    it "falls back to the zenith when the center is the pole" do
      projection = described_class.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5,
        altitude: degrees(0),
        azimuth: degrees(90),
        field_of_view: degrees(30),
        orientation: :equatorial,
        pole: [0.0, 1.0, 0.0]
      )

      point = projection.project(altitude: degrees(10), azimuth: degrees(90))

      expect(point.x).to be_finite
      expect(point.y).to be < 200
    end
  end

  describe "#project with a mirror" do
    it "puts the east on the right and the west on the left" do
      projection = looking_south(mirrored: true)

      east = projection.project(altitude: degrees(30), azimuth: degrees(150))
      west = projection.project(altitude: degrees(30), azimuth: degrees(210))

      expect(east.x).to be > 200
      expect(west.x).to be < 200
    end

    it "keeps the zenith at the top" do
      projection = looking_south(mirrored: true)

      above = projection.project(altitude: degrees(45), azimuth: degrees(180))

      expect(above.y).to be < 200
    end
  end

  describe "#project with a rotation" do
    it "turns the map by half a turn" do
      projection = looking_south(rotation: degrees(180))

      above = projection.project(altitude: degrees(45), azimuth: degrees(180))
      east = projection.project(altitude: degrees(30), azimuth: degrees(150))

      expect(above.y).to be > 200
      expect(east.x).to be > 200
    end

    it "turns the map clockwise by a quarter turn" do
      projection = looking_south(rotation: degrees(90))

      above = projection.project(altitude: degrees(45), azimuth: degrees(180))

      expect(above.x).to be > 200
      expect(above.y.round(2)).to eq(200)
    end

    it "turns a mirrored map the same way" do
      projection = looking_south(rotation: degrees(180), mirrored: true)

      above = projection.project(altitude: degrees(45), azimuth: degrees(180))
      east = projection.project(altitude: degrees(30), azimuth: degrees(150))

      expect(above.y).to be > 200
      expect(east.x).to be < 200
    end
  end

  describe "#project orientation" do
    it "puts the zenith at the top when it is outside the view" do
      projection = southern_view(altitude: 40, field_of_view: 30)

      point = projection.project(altitude: degrees(45), azimuth: degrees(180))

      expect(point.y).to be < 200
    end

    it "puts the north at the top when the zenith is the center" do
      projection = southern_view(altitude: 90, field_of_view: 30)

      point = projection.project(altitude: degrees(85), azimuth: degrees(0))

      expect(point.y).to be < 200
    end

    it "stays defined when the pole is at the zenith and in the center" do
      projection = described_class.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5,
        altitude: degrees(90),
        azimuth: degrees(0),
        field_of_view: degrees(30),
        orientation: :equatorial,
        pole: [0.0, 0.0, 1.0]
      )

      point = projection.project(altitude: degrees(85), azimuth: degrees(0))

      expect(point.x).to be_finite
      expect(point.y).to be_finite
    end

    it "puts the north at the top when the zenith is in the view" do
      projection = described_class.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5,
        altitude: degrees(89),
        azimuth: degrees(0),
        field_of_view: degrees(30)
      )

      point = projection.project(altitude: degrees(85), azimuth: degrees(0))

      expect(point.y).to be < 200
    end

    it "stays defined for a view of the whole sky centered on the horizon" do
      projection = described_class.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5,
        altitude: degrees(0),
        azimuth: degrees(0),
        field_of_view: degrees(180)
      )

      point = projection.project(altitude: degrees(45), azimuth: degrees(90))

      expect(point.x).to be_finite
      expect(point.y).to be_finite
    end
  end

  describe "#scale_at" do
    it "gives the same scale as the full sky around the zenith" do
      full = Skymap::Projection::Stereographic.new(
        center: Skymap::Point.new(x: 200, y: 200),
        radius: 198.5
      )
      zenith = southern_view(altitude: 90, field_of_view: 180)

      expected = full.scale_at(altitude: degrees(35), azimuth: degrees(250))
      scale = zenith.scale_at(altitude: degrees(35), azimuth: degrees(250))

      expect(scale).to be_within(1e-9).of(expected)
    end

    it "gives the pixels of an angle at the center of the view" do
      projection = southern_view(altitude: 30, field_of_view: 60)

      scale = projection.scale_at(altitude: degrees(30), azimuth: degrees(180))
      one_degree = scale * Math::PI / 180

      expect(one_degree.round(2)).to eq(6.46)
    end
  end

  def looking_south(**options)
    described_class.new(
      center: Skymap::Point.new(x: 200, y: 200),
      radius: 198.5,
      altitude: degrees(30),
      azimuth: degrees(180),
      field_of_view: degrees(60),
      **options
    )
  end

  def southern_view(altitude:, field_of_view:)
    described_class.new(
      center: Skymap::Point.new(x: 200, y: 200),
      radius: 198.5,
      altitude: degrees(altitude),
      azimuth: degrees(180),
      field_of_view: degrees(field_of_view)
    )
  end

  def degrees(value)
    Astronoby::Angle.from_degrees(value)
  end
end
