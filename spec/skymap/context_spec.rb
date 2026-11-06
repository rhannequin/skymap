# frozen_string_literal: true

RSpec.describe Skymap::Context do
  describe "#horizontal" do
    it "computes the position of a point of the sky once" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      polaris = star(right_ascension: 2.53, declination: 89.26, magnitude: 2)

      first = context.horizontal(polaris)
      second = context.horizontal(polaris)

      expect(second).to be(first)
    end
  end

  describe "#horizontal with proper motion" do
    {
      "Arcturus" => [14.261028, 19.1825, -0.04, -1093, -1998, 90, -5],
      "Sirius" => [6.752472, -16.716111, -1.46, -553, -1205, 375, -8],
      "61 Cygni A" => [21.115167, 38.745833, 5.21, 4136, 3203, 292, -64],
      "Groombridge 1830" => [11.883, 37.718611, 6.45, 4003, -5813, 116, -98]
    }.each do |name, (ra, dec, magnitude, pm_ra, pm_dec, parallax, velocity)|
      it "puts #{name} where the Astronoby pipeline puts it" do
        context = context_at(
          latitude: 48.8575,
          canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
        )
        moving = star(
          right_ascension: ra,
          declination: dec,
          magnitude: magnitude,
          **motion(
            proper_motion_ra: pm_ra,
            proper_motion_dec: pm_dec,
            parallax: parallax,
            radial_velocity: velocity
          )
        )
        expected = Astronoby::DeepSkyObject.new(
          equatorial_coordinates: moving.equatorial_coordinates,
          proper_motion_ra: moving.proper_motion_ra,
          proper_motion_dec: moving.proper_motion_dec,
          parallax: moving.parallax,
          radial_velocity: moving.radial_velocity
        ).at(context.instant).observed_by(context.observer).horizontal

        horizontal = context.horizontal(moving)

        expect((horizontal.altitude.degrees - expected.altitude.degrees) * 3600)
          .to be_within(0.01).of(0)
        expect(
          (horizontal.azimuth.degrees - expected.azimuth.degrees) * 3600 *
            horizontal.altitude.cos
        ).to be_within(0.01).of(0)
      end
    end

    it "moves a star without a parallax or a radial velocity" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      still = star(right_ascension: 14.261028, declination: 19.1825,
        magnitude: -0.04)
      moving = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: -0.04,
        **motion(proper_motion_ra: -1093, proper_motion_dec: -1998)
      )

      shift = angular_distance(context.horizontal(still),
        context.horizontal(moving))

      expect(shift.degrees * 3600).to be_within(0.2).of(
        Math.hypot(1.093, 1.998) * years_since_j2000(context.instant)
      )
    end

    it "leaves a star without proper motion at its catalog position" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      still = star(right_ascension: 14.261028, declination: 19.1825,
        magnitude: -0.04)

      horizontal = context.horizontal(still)

      expected = context.horizontal_coordinates(still.equatorial_coordinates)
      expect(horizontal.altitude).to eq(expected.altitude)
      expect(horizontal.azimuth).to eq(expected.azimuth)
    end

    it "propagates a star once" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      moving = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: -0.04,
        **motion(
          proper_motion_ra: -1093,
          proper_motion_dec: -1998,
          parallax: 90,
          radial_velocity: -5
        )
      )
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      context.horizontal(moving)
      context.position(moving)
      context.horizontal(moving)

      expect(Astronoby::StellarPropagation)
        .to have_received(:equatorial_coordinates_for).once
    end

    it "puts a star with a high proper motion where it is on a zoomed chart" do
      moving = star(
        right_ascension: 21.115167,
        declination: 38.745833,
        magnitude: 5.21,
        **motion(
          proper_motion_ra: 4136,
          proper_motion_dec: 3203,
          parallax: 292,
          radial_velocity: -64
        )
      )
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: Skymap::View.new(
          center: moving.equatorial_coordinates,
          field_of_view: Astronoby::Angle.from_degrees(0.5)
        )
      )
      layer = Skymap::Layers::Stars.new(stars: [moving], magnitude_limit: 6)

      dot = layer.elements(context).first

      distance = sky_angle_between(
        canvas.center,
        dot.center,
        canvas: canvas,
        field_of_view: 0.5
      )
      expected = Math.hypot(4.136, 3.203) *
        years_since_j2000(context.instant) / 3600
      expect(distance).to be_within(0.0002).of(expected)
    end
  end

  def angular_distance(first, second)
    Astronoby::Angle.acos(
      first.altitude.sin * second.altitude.sin +
        first.altitude.cos * second.altitude.cos *
        (first.azimuth - second.azimuth).cos
    )
  end

  describe "#horizontal_coordinates" do
    it "computes the position of the same coordinates once" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      first = context.horizontal_coordinates(
        equatorial(right_ascension: 2.53, declination: 89.26)
      )
      second = context.horizontal_coordinates(
        equatorial(right_ascension: 2.53, declination: 89.26)
      )

      expect(second).to be(first)
    end

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

  describe "#horizontal_coordinates at the date of the chart" do
    it "puts the pole of date at the altitude of the latitude" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      pole = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(5),
        declination: Astronoby::Angle.from_degrees(90),
        epoch: context.instant.tt
      )

      horizontal = context.horizontal_coordinates(pole)

      expect(horizontal.altitude.degrees).to be_within(1e-6).of(48.8575)
      expect(horizontal.azimuth.degrees % 360)
        .to be_within(1e-4).of(0).or be_within(1e-4).of(360)
    end

    it "does not give the same position as the same numbers at J2000" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      of_date = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(5),
        declination: Astronoby::Angle.from_degrees(20),
        epoch: context.instant.tt
      )
      j2000 = equatorial(right_ascension: 5, declination: 20)

      first = context.horizontal_coordinates(of_date)
      second = context.horizontal_coordinates(j2000)

      expect(first.altitude.degrees)
        .not_to be_within(0.01).of(second.altitude.degrees)
    end

    it "rejects coordinates at another epoch" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      coordinates = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(5),
        declination: Astronoby::Angle.from_degrees(20),
        epoch: Astronoby::JulianDate::J2000 + 1000
      )

      expect { context.horizontal_coordinates(coordinates) }
        .to raise_error(ArgumentError, /J2000 or at the date of the chart/)
    end
  end

  describe "#to_horizontal" do
    it "converts equatorial coordinates to horizontal ones" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      coordinates = equatorial(right_ascension: 3, declination: 30)

      horizontal = context.to_horizontal(coordinates)

      expect(horizontal.altitude.degrees.round).to eq(30)
    end

    it "gives horizontal coordinates back as they are" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 30)

      horizontal = context.to_horizontal(view.center)

      expect(horizontal).to be(view.center)
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

  describe "#scale_at_point" do
    it "gives the pixels per radian at a point of the map" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 60)
      )

      center = context.scale_at_point(canvas.center)
      edge = context.scale_at_point(Skymap::Point.new(x: 200, y: 1.5))

      expect((center * Math::PI / 180).round(2)).to eq(6.46)
      expect(edge).to be > center
    end

    it "matches the scale of a place of the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 30, azimuth: 180, field_of_view: 120)
      )
      altitude = Astronoby::Angle.from_degrees(70)
      azimuth = Astronoby::Angle.from_degrees(150)

      point = context.project(altitude: altitude, azimuth: azimuth)
      expected = context.span(
        Astronoby::Angle.from_radians(1),
        altitude: altitude,
        azimuth: azimuth
      )

      expect(context.scale_at_point(point)).to be_within(1e-6).of(expected)
    end

    it "is the scale of the whole sky without a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      altitude = Astronoby::Angle.from_degrees(20)
      azimuth = Astronoby::Angle.from_degrees(100)

      point = context.project(altitude: altitude, azimuth: azimuth)

      expect(context.scale_at_point(point))
        .to be_within(1e-6).of(198.5 / (1 + altitude.sin))
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
        view: Skymap::View.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(30)
        )
      )
      horizontal = context.horizontal_coordinates(center)

      point = context.project(
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      )

      expect([point.x.round(2), point.y.round(2)]).to eq([200, 200])
    end
  end

  describe "#project with a view centered at the date of the chart" do
    it "centers the view on equatorial coordinates of date" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      center = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(3),
        declination: Astronoby::Angle.from_degrees(30),
        epoch: instant.tt
      )
      context = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: instant,
        canvas: canvas,
        view: Skymap::View.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(30)
        )
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

  describe "#project with an equatorial orientation" do
    it "puts the celestial pole above the center of the view" do
      view = Skymap::View.new(
        center: Astronoby::Coordinates::Horizontal.new(
          altitude: Astronoby::Angle.from_degrees(60),
          azimuth: Astronoby::Angle.zero,
          observer: observer_at(latitude: 48.8575)
        ),
        field_of_view: Astronoby::Angle.from_degrees(40),
        orientation: :equatorial
      )
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )

      pole = context.project(
        altitude: Astronoby::Angle.from_degrees(48.8575),
        azimuth: Astronoby::Angle.zero
      )

      expect(pole.x.round(2)).to eq(200)
      expect(pole.y).to be < 200
    end

    it "puts the celestial pole below the center with the zenith at the top" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 60, azimuth: 0, field_of_view: 40)
      )

      pole = context.project(
        altitude: Astronoby::Angle.from_degrees(48.8575),
        azimuth: Astronoby::Angle.zero
      )

      expect(pole.y).to be > 200
    end
  end
end
