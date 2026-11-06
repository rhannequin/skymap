# frozen_string_literal: true

RSpec.describe Skymap::Context do
  catalog = Skymap::Catalog::Stars.new.to_a

  def canvas
    Skymap::Canvas.new(size: 400, padding: 1.5)
  end

  def view_on(right_ascension:, declination:, field_of_view:, **options)
    Skymap::View.new(
      center: equatorial(
        right_ascension: right_ascension,
        declination: declination
      ),
      field_of_view: Astronoby::Angle.from_degrees(field_of_view),
      **options
    )
  end

  def full_position(context, star)
    horizontal = context.horizontal_coordinates(
      star.coordinates_at(context.instant)
    )

    context.project(altitude: horizontal.altitude, azimuth: horizontal.azimuth)
  end

  def full_dots(context, stars, magnitude_limit)
    star_size = Skymap::StarSize.for(
      canvas: context.canvas,
      magnitude_limit: magnitude_limit
    )

    faintest_first = stars.each_with_index.sort_by { |star, index|
      [-star.magnitude, index]
    }.map(&:first)

    faintest_first.filter_map do |star|
      next if star.magnitude > magnitude_limit

      horizontal = context.horizontal_coordinates(
        star.coordinates_at(context.instant)
      )
      next if horizontal.altitude.negative?

      center = context.project(
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      )
      radius = star_size.radius(star.magnitude)
      next unless context.in_view?(center, radius)

      Skymap::Renderer::Dot.new(center: center, radius: radius)
    end
  end

  def sidereal_hours(context)
    Astronoby::LocalApparentSiderealTime.from_utc(
      context.instant.to_time,
      longitude: Astronoby::Angle.zero
    ).time
  end

  def same_sky_position(first, second)
    first.altitude.radians == second.altitude.radians &&
      first.azimuth.radians == second.azimuth.radians
  end

  def pixels_between(first, second)
    Math.hypot(first.x - second.x, first.y - second.y)
  end

  def propagations
    count = 0
    allow(Astronoby::StellarPropagation)
      .to receive(:equatorial_coordinates_for)
      .and_wrap_original do |original, **kwargs|
        count += 1
        original.call(**kwargs)
      end

    yield

    count
  end

  views = {
    "the whole sky" => nil,
    "1 degree on Albireo" => {
      right_ascension: 19.512028, declination: 27.959722, field_of_view: 1
    },
    "0.25 degree on 61 Cygni A" => {
      right_ascension: 21.115167, declination: 38.745833, field_of_view: 0.25
    },
    "2 degrees on 61 Cygni A, equatorial and rotated" => {
      right_ascension: 21.115167,
      declination: 38.745833,
      field_of_view: 2,
      orientation: :equatorial,
      rotation: Astronoby::Angle.from_degrees(35)
    }
  }

  describe "#position against the full propagation" do
    views.each do |name, view|
      it "stays within 0.005 pixel for every star of the catalog on #{name}" do
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view && view_on(**view)
        )

        gaps = catalog.map do |star|
          pixels_between(context.position(star), full_position(context, star))
        end

        expect(gaps.max).to be < 0.005
      end

      it "draws the same dots as the full propagation on #{name}" do
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view && view_on(**view)
        )
        expected = full_dots(context, catalog, 8)

        dots = Skymap::Layers::Stars.new(stars: catalog, magnitude_limit: 8)
          .elements(context)

        expect(dots.size).to eq(expected.size)
        expect(dots.map(&:radius)).to eq(expected.map(&:radius))
        expect(
          dots.zip(expected).map { |dot, other|
            pixels_between(dot.center, other.center)
          }.max
        ).to be < 0.005
      end
    end

    it "draws at least one star in each zoomed view" do
      contexts = views.values.compact.map do |view|
        context_at(latitude: 48.8575, canvas: canvas, view: view_on(**view))
      end

      counts = contexts.map do |context|
        Skymap::Layers::Stars.new(stars: catalog, magnitude_limit: 8)
          .elements(context).size
      end

      expect(counts).to all(be > 0)
    end
  end

  describe "#horizontal skipping the propagation" do
    it "keeps the catalog position of a star that barely moves" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      slow = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: 2,
        **motion(proper_motion_ra: 10, proper_motion_dec: -10)
      )
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      horizontal = context.horizontal(slow)

      expect(Astronoby::StellarPropagation)
        .not_to have_received(:equatorial_coordinates_for)
      expected = context.horizontal_coordinates(slow.equatorial_coordinates)
      expect(same_sky_position(horizontal, expected)).to be(true)
    end

    it "propagates a star that moves more than a pixel" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      fast = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: 2,
        **motion(proper_motion_ra: -1093, proper_motion_dec: -1998)
      )
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      context.horizontal(fast)

      expect(Astronoby::StellarPropagation)
        .to have_received(:equatorial_coordinates_for).once
    end

    it "does not touch a star without a proper motion" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      still = star(right_ascension: 14.261028, declination: 19.1825,
        magnitude: 2)
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      horizontal = context.horizontal(still)

      expect(Astronoby::StellarPropagation)
        .not_to have_received(:equatorial_coordinates_for)
      expected = context.horizontal_coordinates(still.equatorial_coordinates)
      expect(same_sky_position(horizontal, expected)).to be(true)
    end

    it "does not propagate at the instant of J2000" do
      context = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_terrestrial_time(
          Astronoby::JulianDate::J2000
        ),
        canvas: canvas
      )
      fast = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: 2,
        **motion(proper_motion_ra: -10_000, proper_motion_dec: -10_000)
      )
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      horizontal = context.horizontal(fast)

      expect(Astronoby::StellarPropagation)
        .not_to have_received(:equatorial_coordinates_for)
      expected = context.horizontal_coordinates(fast.equatorial_coordinates)
      expect(same_sky_position(horizontal, expected)).to be(true)
    end

    it "propagates a star just above the tolerance and not one just below" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      overhead = star(
        right_ascension: sidereal_hours(context),
        declination: 48.8575,
        magnitude: 2
      )
      horizontal = context.horizontal(overhead)
      pixels_per_pm = context.span(
        Astronoby::Angle.from_radians(1),
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      ) * years_since_j2000(context.instant) *
        Astronoby::Angle.from_degree_arcseconds(0.001).radians
      below = star(
        right_ascension: sidereal_hours(context),
        declination: 48.8575,
        magnitude: 2,
        **motion(proper_motion_ra: 0, proper_motion_dec: 0.0049 / pixels_per_pm)
      )
      above = star(
        right_ascension: sidereal_hours(context),
        declination: 48.8575,
        magnitude: 2,
        **motion(proper_motion_ra: 0, proper_motion_dec: 0.0051 / pixels_per_pm)
      )

      counts = [below, above].map do |moving|
        propagations { context.horizontal(moving) }
      end

      expect(counts).to eq([0, 1])
    end

    it "propagates a star whose shift cannot be bounded" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      approaching = star(
        right_ascension: 14.261028,
        declination: 19.1825,
        magnitude: 2,
        **motion(
          proper_motion_ra: 1,
          proper_motion_dec: 1,
          parallax: 500_000,
          radial_velocity: -200_000
        )
      )
      allow(Astronoby::StellarPropagation)
        .to receive(:equatorial_coordinates_for).and_call_original

      context.horizontal(approaching)

      expect(Astronoby::StellarPropagation)
        .to have_received(:equatorial_coordinates_for).once
    end
  end

  describe "#possibly_visible?" do
    it "accepts the sky above the horizon and rejects the rest" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      circumpolar = star(right_ascension: 0, declination: 89, magnitude: 2)
      never_rising = star(right_ascension: 0, declination: -89, magnitude: 2)

      expect(context.possibly_visible?(circumpolar)).to be(true)
      expect(context.possibly_visible?(never_rising)).to be(false)
    end

    it "accepts a star below the horizon that may rise" do
      context = context_at(latitude: 48.8575, canvas: canvas)
      rising = (sidereal_hours(context) + 6) % 24
      resting = star(right_ascension: rising, declination: -0.8, magnitude: 2)
      racing = star(
        right_ascension: rising,
        declination: -0.8,
        magnitude: 2,
        **motion(proper_motion_ra: 0, proper_motion_dec: 150_000)
      )

      expect(context.possibly_visible?(resting)).to be(false)
      expect(context.possibly_visible?(racing)).to be(true)
    end

    it "accepts a star inside the view and rejects one outside it" do
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_on(right_ascension: 19.5, declination: 28,
          field_of_view: 2)
      )
      inside = star(right_ascension: 19.5, declination: 28.99, magnitude: 5)
      outside = star(right_ascension: 19.5, declination: 29.01, magnitude: 5)

      expect(context.possibly_visible?(inside)).to be(true)
      expect(context.possibly_visible?(outside)).to be(false)
    end

    it "accepts a star just outside the disk as far as the margin goes" do
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_on(right_ascension: 19.5, declination: 28,
          field_of_view: 2)
      )
      near = star(right_ascension: 19.5, declination: 29.04, magnitude: 5)
      far = star(right_ascension: 19.5, declination: 29.06, magnitude: 5)

      expect(context.possibly_visible?(near, 10)).to be(true)
      expect(context.possibly_visible?(far, 10)).to be(false)
    end

    it "accepts a star outside the view that moves into it" do
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_on(right_ascension: 19.5, declination: 28,
          field_of_view: 0.1)
      )
      distance = 100.0 * years_since_j2000(context.instant) / 3600
      still = star(right_ascension: 19.5, declination: 28 + distance,
        magnitude: 5)
      racing = star(
        right_ascension: 19.5,
        declination: 28 + distance,
        magnitude: 5,
        **motion(proper_motion_ra: 0, proper_motion_dec: -100_000)
      )

      expect(context.possibly_visible?(still)).to be(false)
      expect(context.possibly_visible?(racing)).to be(true)
      expect(context.in_view?(context.position(racing))).to be(true)
    end

    it "accepts a star that has no proper motion exactly where it is" do
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_on(right_ascension: 19.5, declination: 28,
          field_of_view: 2)
      )
      centered = star(right_ascension: 19.5, declination: 28, magnitude: 5)

      expect(context.possibly_visible?(centered)).to be(true)
    end
  end

  describe "#possibly_visible? on a zoomed view" do
    it "keeps the propagation to the stars near the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_on(right_ascension: 21.115167, declination: 38.745833,
          field_of_view: 0.25)
      )
      layer = Skymap::Layers::Stars.new(stars: catalog, magnitude_limit: 8)

      count = propagations { layer.elements(context) }

      expect(count).to be < 50
    end
  end
end
