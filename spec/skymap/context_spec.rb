# frozen_string_literal: true

RSpec.describe Skymap::Context do
  describe "#horizontal" do
    it "computes the position of a point of the sky once" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      polaris = star(right_ascension: 2.53, declination: 89.26, magnitude: 2)
      same_polaris = star(
        right_ascension: 2.53,
        declination: 89.26,
        magnitude: 2
      )

      first = context.horizontal(polaris)
      second = context.horizontal(same_polaris)

      expect(second).to be(first)
    end
  end

  describe "#horizontal_coordinates" do
    it "gives the position of coordinates of the sky" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      coordinates = equatorial(right_ascension: 3, declination: 30)

      horizontal = context.horizontal_coordinates(coordinates)

      expect(horizontal.altitude.degrees.round).to eq(30)
    end
  end

  describe "#position" do
    it "places a star on the canvas where its position projects" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      polaris = star(right_ascension: 2.53, declination: 89.26, magnitude: 2)
      horizontal = context.horizontal(polaris)

      position = context.position(polaris)

      expect(position).to eq(
        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      )
    end
  end

  describe "#project" do
    it "projects the horizon on the edge of the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      point = context.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.zero
      )

      expect(point).to eq(Skymap::Point.new(x: 200, y: 20))
    end

    it "projects the horizon on a circle of the given radius" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      point = context.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.zero,
        radius: 190
      )

      expect(point).to eq(Skymap::Point.new(x: 200, y: 10))
    end
  end

  describe "#full_sky?" do
    it "is the whole sky without a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      expect(context.full_sky?).to be(true)
    end

    it "is not the whole sky with a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )

      expect(context.full_sky?).to be(false)
    end
  end

  describe "#project" do
    it "puts the center of the view at the center of the canvas" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )

      point = context.project(
        altitude: Astronoby::Angle.from_degrees(40),
        azimuth: Astronoby::Angle.from_degrees(180)
      )

      expect([point.x.round(2), point.y.round(2)]).to eq([200, 200])
    end

    it "centers the view on equatorial coordinates" do
      center = equatorial(right_ascension: 3, declination: 30)
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: Skymap::View.new(center: center, field_of_view: 30)
      )
      horizontal = context.horizontal_coordinates(center)

      point = context.project(
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      )

      expect([point.x.round(2), point.y.round(2)]).to eq([200, 200])
    end
  end

  describe "#in_view?" do
    it "accepts every point without a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      expect(context.in_view?(Skymap::Point.new(x: 5000, y: 5000))).to be(true)
    end

    it "accepts the points inside the disk and rejects the others" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )

      inside = Skymap::Point.new(x: 200, y: 20)
      outside = Skymap::Point.new(x: 5, y: 5)

      expect(context.in_view?(inside)).to be(true)
      expect(context.in_view?(outside)).to be(false)
    end

    it "accepts a point outside the disk that is close enough" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )
      point = Skymap::Point.new(x: 200, y: 0)

      expect(context.in_view?(point, 5)).to be(true)
    end
  end

  describe "#reachable?" do
    it "reaches the whole sky without a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      horizontal = context.horizontal(
        star(right_ascension: 0, declination: 89, magnitude: 2)
      )

      expect(context.reachable?(horizontal)).to be(true)
    end

    it "leaves out the sky behind the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 10, azimuth: 180, field_of_view: 30)
      )
      behind = Astronoby::Coordinates::Horizontal.new(
        altitude: Astronoby::Angle.from_degrees(5),
        azimuth: Astronoby::Angle.zero,
        observer: observer_at(latitude: 48.8575)
      )
      ahead = Astronoby::Coordinates::Horizontal.new(
        altitude: Astronoby::Angle.from_degrees(20),
        azimuth: Astronoby::Angle.from_degrees(170),
        observer: observer_at(latitude: 48.8575)
      )

      expect(context.reachable?(behind)).to be(false)
      expect(context.reachable?(ahead)).to be(true)
    end
  end
end
