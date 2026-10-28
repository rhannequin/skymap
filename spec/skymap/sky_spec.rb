# frozen_string_literal: true

RSpec.describe Skymap::Sky do
  describe "#horizontal" do
    it "agrees with the position Astronoby computes for a point of the sky" do
      observer = observer_at(latitude: 48.8575)
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      sky = described_class.new(observer: observer, instant: instant)
      points = [
        equatorial(right_ascension: 6.752, declination: -16.716),
        equatorial(right_ascension: 2.53, declination: 89.26),
        equatorial(right_ascension: 14.66, declination: -60.83),
        equatorial(right_ascension: 23.9, declination: 0.1)
      ]

      differences = points.map do |point|
        expected = Astronoby::DeepSkyObject
          .new(equatorial_coordinates: point)
          .at(instant)
          .observed_by(observer)
          .horizontal
        actual = sky.horizontal(point)

        [
          (actual.altitude.degrees - expected.altitude.degrees).abs,
          (actual.azimuth.degrees - expected.azimuth.degrees).abs
        ]
      end

      expect(differences.flatten.max).to be < 0.001
    end

    it "keeps the azimuth between 0 and 360 degrees" do
      observer = observer_at(latitude: 48.8575)
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      sky = described_class.new(observer: observer, instant: instant)

      azimuths = (0...24).map do |hours|
        sky.horizontal(equatorial(right_ascension: hours, declination: 20))
          .azimuth.degrees
      end

      expect(azimuths).to all(be_between(0, 360))
    end
  end
end
