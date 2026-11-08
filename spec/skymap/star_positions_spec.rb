# frozen_string_literal: true

RSpec.describe Skymap::StarPositions do
  def star_positions
    described_class.new(
      instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
      convert: ->(coordinates) { coordinates },
      scale: ->(altitude:, azimuth:) { 1.0 }
    )
  end

  describe "#maximum_shift" do
    it "grows with the radial velocity of the star" do
      positions = star_positions
      resting = star(right_ascension: 1, declination: 10, magnitude: 5,
        **motion(proper_motion_ra: 500, proper_motion_dec: 500,
          radial_velocity: 0))
      receding = star(right_ascension: 1, declination: 10, magnitude: 5,
        **motion(proper_motion_ra: 500, proper_motion_dec: 500,
          radial_velocity: 100_000))

      growth = (positions.maximum_shift(receding) - 1e-6) /
        (positions.maximum_shift(resting) - 1e-6)

      expect(growth).to be_within(1e-6).of(1 / (1 - 100_000.0 / 299_792.458))
    end

    it "is the slack alone for a star without proper motion" do
      positions = star_positions
      fixed = star(right_ascension: 1, declination: 10, magnitude: 5)

      shift = positions.maximum_shift(fixed)

      expect(shift).to be_within(1e-12).of(1e-6)
    end
  end
end
