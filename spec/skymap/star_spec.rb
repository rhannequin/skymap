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
