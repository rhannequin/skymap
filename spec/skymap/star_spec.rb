# frozen_string_literal: true

RSpec.describe Skymap::Star do
  describe ".new" do
    it "has no astrometry by default" do
      star = star(right_ascension: 6.75, declination: -16.7, magnitude: -1.46)

      expect(star.proper_motion_ra).to be_nil
      expect(star.proper_motion_dec).to be_nil
      expect(star.parallax).to be_nil
      expect(star.radial_velocity).to be_nil
    end

    it "takes a proper motion, a parallax and a radial velocity" do
      proper_motion_ra = Astronoby::AngularVelocity
        .from_milliarcseconds_per_year(-546)
      proper_motion_dec = Astronoby::AngularVelocity
        .from_milliarcseconds_per_year(-1223)
      parallax = Astronoby::Angle.from_degree_arcseconds(0.379)
      radial_velocity = Astronoby::Velocity.from_kilometers_per_second(-5.5)

      star = star_with(
        proper_motion_ra: proper_motion_ra,
        proper_motion_dec: proper_motion_dec,
        parallax: parallax,
        radial_velocity: radial_velocity
      )

      expect(star.proper_motion_ra).to eq(proper_motion_ra)
      expect(star.proper_motion_dec).to eq(proper_motion_dec)
      expect(star.parallax).to eq(parallax)
      expect(star.radial_velocity).to eq(radial_velocity)
    end

    it "takes a radial velocity or a parallax without a proper motion" do
      parallax = Astronoby::Angle.from_degree_arcseconds(0.379)
      radial_velocity = Astronoby::Velocity.from_kilometers_per_second(-5.5)

      star = star_with(parallax: parallax, radial_velocity: radial_velocity)

      expect(star.parallax).to eq(parallax)
      expect(star.radial_velocity).to eq(radial_velocity)
    end

    it "rejects a proper motion with coordinates at another epoch" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      of_date = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(6.75),
        declination: Astronoby::Angle.from_degrees(-16.7),
        epoch: instant.tt
      )

      expect {
        described_class.new(
          hr: 2491,
          equatorial_coordinates: of_date,
          magnitude: -1.46,
          **motion(proper_motion_ra: -553, proper_motion_dec: -1205)
        )
      }.to raise_error(
        ArgumentError,
        /equatorial_coordinates must be at J2000 when a proper motion/
      )
    end

    it "rejects a proper motion added with coordinates at another epoch" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      of_date = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(6.75),
        declination: Astronoby::Angle.from_degrees(-16.7),
        epoch: instant.tt
      )
      still = star_with.with(equatorial_coordinates: of_date)

      expect {
        still.with(
          **motion(proper_motion_ra: -553, proper_motion_dec: -1205)
        )
      }.to raise_error(ArgumentError, /must be at J2000/)
    end

    it "takes coordinates at another epoch without a proper motion" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      of_date = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(6.75),
        declination: Astronoby::Angle.from_degrees(-16.7),
        epoch: instant.tt
      )

      star = star_with.with(equatorial_coordinates: of_date)

      expect(star.coordinates_at(instant)).to eq(of_date)
    end

    it "rejects a proper motion in right ascension that is not a velocity" do
      expect {
        star_with(
          proper_motion_ra: -546,
          proper_motion_dec: Astronoby::AngularVelocity.zero
        )
      }.to raise_error(
        ArgumentError,
        /proper_motion_ra must be an Astronoby::AngularVelocity or nil/
      )
    end

    it "rejects a proper motion in declination that is not a velocity" do
      expect {
        star_with(
          proper_motion_ra: Astronoby::AngularVelocity.zero,
          proper_motion_dec: Astronoby::Angle.zero
        )
      }.to raise_error(
        ArgumentError,
        /proper_motion_dec must be an Astronoby::AngularVelocity or nil/
      )
    end

    it "rejects a proper motion that is not finite" do
      expect {
        star_with(
          proper_motion_ra: Astronoby::AngularVelocity.new(Float::NAN),
          proper_motion_dec: Astronoby::AngularVelocity.zero
        )
      }.to raise_error(ArgumentError, /proper_motion_ra must be/)
    end

    it "rejects a proper motion in only one direction" do
      expect {
        star_with(proper_motion_ra: Astronoby::AngularVelocity.zero)
      }.to raise_error(
        ArgumentError,
        /proper_motion_ra and proper_motion_dec must be given together/
      )
      expect {
        star_with(proper_motion_dec: Astronoby::AngularVelocity.zero)
      }.to raise_error(
        ArgumentError,
        /proper_motion_ra and proper_motion_dec must be given together/
      )
    end

    it "rejects a parallax that is not an angle" do
      expect { star_with(parallax: 0.379) }.to raise_error(
        ArgumentError,
        /parallax must be an Astronoby::Angle above 0 or nil/
      )
    end

    it "rejects a parallax of zero or less" do
      expect { star_with(parallax: Astronoby::Angle.zero) }
        .to raise_error(ArgumentError, /parallax must be/)
      expect {
        star_with(parallax: Astronoby::Angle.from_degree_arcseconds(-0.01))
      }.to raise_error(ArgumentError, /parallax must be/)
    end

    it "rejects a parallax that is not finite" do
      expect {
        star_with(parallax: Astronoby::Angle.from_radians(Float::NAN))
      }.to raise_error(ArgumentError, /parallax must be/)
    end

    it "rejects a radial velocity that is not a velocity" do
      expect { star_with(radial_velocity: -5.5) }.to raise_error(
        ArgumentError,
        /radial_velocity must be an Astronoby::Velocity or nil/
      )
    end

    it "rejects a radial velocity that is not finite" do
      expect {
        star_with(radial_velocity: Astronoby::Velocity.new(Float::INFINITY))
      }.to raise_error(ArgumentError, /radial_velocity must be/)
    end
  end

  describe ".by_hr" do
    it "gives each star under its Harvard Revised number" do
      sirius = star(
        right_ascension: 6.75,
        declination: -16.7,
        magnitude: -1.46,
        hr: 2491
      )
      vega = star(
        right_ascension: 18.6,
        declination: 38.8,
        magnitude: 0.03,
        hr: 7001
      )

      stars = described_class.by_hr([sirius, vega])

      expect(stars).to eq(2491 => sirius, 7001 => vega)
    end
  end

  describe "#coordinates_at" do
    it "moves a star in right ascension by its proper motion" do
      arcturus = arcturus_star
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      years = years_since_j2000(instant)

      coordinates = arcturus.coordinates_at(instant)

      shift = (coordinates.right_ascension.degrees -
        arcturus.equatorial_coordinates.right_ascension.degrees) * 3600 *
        arcturus.equatorial_coordinates.declination.cos
      expect(shift).to be_within(0.1).of(-1.093 * years)
    end

    it "moves a star in declination by its proper motion" do
      arcturus = arcturus_star
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      years = years_since_j2000(instant)

      coordinates = arcturus.coordinates_at(instant)

      shift = (coordinates.declination.degrees -
        arcturus.equatorial_coordinates.declination.degrees) * 3600
      expect(shift).to be_within(0.1).of(-1.998 * years)
    end

    it "gives coordinates at J2000, as the catalog does" do
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))

      coordinates = arcturus_star.coordinates_at(instant)

      expect(coordinates.epoch).to eq(Astronoby::JulianDate::J2000)
    end

    it "leaves a star without proper motion where the catalog puts it" do
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      fixed = star(
        right_ascension: 6.75,
        declination: -16.7,
        magnitude: -1.46,
        parallax: Astronoby::Angle.from_degree_arcseconds(0.379),
        radial_velocity: Astronoby::Velocity.from_kilometers_per_second(-5.5)
      )

      coordinates = fixed.coordinates_at(instant)

      expect(coordinates).to eq(fixed.equatorial_coordinates)
    end

    it "gives the J2000 position at the J2000 instant" do
      j2000 = Astronoby::Instant.from_time(Time.utc(2000, 1, 1, 12))

      arcturus = arcturus_star

      coordinates = arcturus.coordinates_at(j2000)

      expect(
        separation_in_arcseconds(coordinates, arcturus.equatorial_coordinates)
      ).to be < 0.001
    end

    it "assumes a distant star when the parallax is unknown" do
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      known = arcturus_star
      unknown = arcturus_star(parallax: nil)

      with = known.coordinates_at(instant)
      without = unknown.coordinates_at(instant)

      expect(separation_in_arcseconds(with, without)).to be < 0.1
      expect(without).not_to eq(unknown.equatorial_coordinates)
    end

    it "assumes no radial velocity when it is unknown" do
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      still = arcturus_star(radial_velocity: 0)
      unknown = arcturus_star(radial_velocity: nil)

      expected = still.coordinates_at(instant)
      coordinates = unknown.coordinates_at(instant)

      expect(coordinates.right_ascension.radians)
        .to be_within(1e-12).of(expected.right_ascension.radians)
      expect(coordinates.declination.radians)
        .to be_within(1e-12).of(expected.declination.radians)
    end

    it "moves a star that has neither a parallax nor a radial velocity" do
      instant = Astronoby::Instant.from_time(Time.utc(2027, 8, 15, 21))
      bare = arcturus_star(parallax: nil, radial_velocity: nil)
      full = arcturus_star

      without = bare.coordinates_at(instant)
      with = full.coordinates_at(instant)

      expect(separation_in_arcseconds(with, without)).to be < 0.1
    end

    it "rejects an instant that is not an Astronoby::Instant" do
      expect { arcturus_star.coordinates_at(Time.utc(2027, 8, 15, 21)) }
        .to raise_error(
          ArgumentError,
          /instant must be an Astronoby::Instant/
        )
    end
  end

  def arcturus_star(parallax: 90, radial_velocity: -5)
    star(
      hr: 5340,
      right_ascension: 14.261028,
      declination: 19.1825,
      magnitude: -0.04,
      **motion(
        proper_motion_ra: -1093,
        proper_motion_dec: -1998,
        parallax: parallax,
        radial_velocity: radial_velocity
      )
    )
  end

  def separation_in_arcseconds(first, second)
    Math.hypot(
      (first.right_ascension.degrees - second.right_ascension.degrees) * 3600 *
        first.declination.cos,
      (first.declination.degrees - second.declination.degrees) * 3600
    )
  end

  def star_with(**astrometry)
    described_class.new(
      hr: 2491,
      equatorial_coordinates: equatorial(
        right_ascension: 6.75,
        declination: -16.7
      ),
      magnitude: -1.46,
      **astrometry
    )
  end
end
