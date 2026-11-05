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

  describe "#horizontal_of_date" do
    it "puts the pole of date at the altitude of the latitude" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      pole = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(5),
        declination: Astronoby::Angle.from_degrees(90),
        epoch: nil
      )

      horizontal = context.horizontal_of_date(pole)

      expect(horizontal.altitude.degrees).to be_within(1e-6).of(48.8575)
      expect(horizontal.azimuth.degrees % 360)
        .to be_within(1e-4).of(0).or be_within(1e-4).of(360)
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

  describe "#span" do
    it "gives the pixels an angle covers at a place of the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 60)
      )

      pixels = context.span(
        Astronoby::Angle.from_degrees(1),
        altitude: Astronoby::Angle.from_degrees(30),
        azimuth: Astronoby::Angle.from_degrees(180)
      )

      expect(pixels.round(2)).to eq(6.46)
    end

    it "covers more pixels when the field of view is smaller" do
      wide = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 60)
      )
      narrow = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 6)
      )
      arguments = {
        altitude: Astronoby::Angle.from_degrees(30),
        azimuth: Astronoby::Angle.from_degrees(180)
      }
      angle = Astronoby::Angle.from_degrees(1)

      expect(narrow.span(angle, **arguments))
        .to be > wide.span(angle, **arguments) * 9
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

  describe "#crosses_view?" do
    it "accepts every line without a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      line = [Skymap::Point.new(x: 5000, y: 0),
        Skymap::Point.new(x: 6000, y: 0)]

      expect(context.crosses_view?(line)).to be(true)
    end

    it "accepts a line that goes through the disk from outside" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )
      line = [Skymap::Point.new(x: -500, y: 200),
        Skymap::Point.new(x: 900, y: 200)]

      expect(context.crosses_view?(line)).to be(true)
    end

    it "rejects a line that stays outside the disk" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )
      line = [Skymap::Point.new(x: -500, y: -100),
        Skymap::Point.new(x: 900, y: -100)]

      expect(context.crosses_view?(line)).to be(false)
    end

    it "judges a single point by its place" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 30)
      )

      inside = [Skymap::Point.new(x: 200, y: 200)]
      outside = [Skymap::Point.new(x: 5, y: 5)]

      expect(context.crosses_view?(inside)).to be(true)
      expect(context.crosses_view?(outside)).to be(false)
    end
  end

  describe "#disk_radius" do
    it "keeps the default radius in the whole sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      radius = context.disk_radius(
        6,
        angular_diameter: Astronoby::Angle.from_degrees(30),
        altitude: Astronoby::Angle.from_degrees(30),
        azimuth: Astronoby::Angle.from_degrees(180)
      )

      expect(radius).to eq(6)
    end

    it "grows to the size of the angle in a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 60)
      )

      radius = context.disk_radius(
        6,
        angular_diameter: Astronoby::Angle.from_degrees(4),
        altitude: Astronoby::Angle.from_degrees(30),
        azimuth: Astronoby::Angle.from_degrees(180)
      )

      expect(radius.round(2)).to eq(12.93)
    end

    it "keeps the default radius when the angle is smaller" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 60)
      )

      radius = context.disk_radius(
        6,
        angular_diameter: Astronoby::Angle.from_degrees(1),
        altitude: Astronoby::Angle.from_degrees(30),
        azimuth: Astronoby::Angle.from_degrees(180)
      )

      expect(radius).to eq(6)
    end
  end
end
