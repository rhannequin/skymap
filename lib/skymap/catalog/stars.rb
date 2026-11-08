# frozen_string_literal: true

module Skymap
  module Catalog
    class Stars
      include Enumerable

      PATH = File.expand_path("../../../data/stars.bin", __dir__)

      def self.records
        @records ||= StarRecords.new(File.binread(PATH))
      end
      private_class_method :records

      def each
        return enum_for(:each) unless block_given?

        records.each { |record| yield star_for(record) }
      end

      def search(magnitude_limit: nil, cone: nil)
        return whole_sky(magnitude_limit) unless cone

        records.each(
          magnitude_limit: magnitude_limit,
          center: [
            cone.center.right_ascension.degrees,
            cone.center.declination.degrees
          ],
          radius: cone.radius.degrees
        ).map { |record| star_for(record) }
      end

      def by_hr
        @by_hr ||= records.each_with_hr.to_h do |record|
          [record.hr, star_for(record)]
        end
      end

      private

      def records
        self.class.send(:records)
      end

      def whole_sky(magnitude_limit)
        stars = StarRecords.bands_within(magnitude_limit).flat_map do |band|
          band_stars(band)
        end
        return stars unless magnitude_limit

        stars.select { |star| star.magnitude <= magnitude_limit }
      end

      def band_stars(band)
        @band_stars ||= {}
        @band_stars[band] ||= records.each_in_band(band)
          .map { |record| star_for(record) }.freeze
      end

      def star_for(record)
        return star_from(record) unless record.hr

        @hr_stars ||= {}
        @hr_stars[record.hr] ||= star_from(record)
      end

      def star_from(record)
        Star.new(
          hr: record.hr,
          equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
            right_ascension: Astronoby::Angle.from_degrees(
              record.right_ascension
            ),
            declination: Astronoby::Angle.from_degrees(record.declination),
            epoch: Astronoby::JulianDate::J2000
          ),
          magnitude: record.magnitude,
          proper_motion_ra: proper_motion(record.proper_motion_ra),
          proper_motion_dec: proper_motion(record.proper_motion_dec),
          parallax: parallax(record.parallax),
          radial_velocity: radial_velocity(record.radial_velocity)
        )
      end

      def proper_motion(milliarcseconds_per_year)
        return unless milliarcseconds_per_year

        Astronoby::AngularVelocity.from_milliarcseconds_per_year(
          milliarcseconds_per_year
        )
      end

      def parallax(milliarcseconds)
        return unless milliarcseconds

        Astronoby::Angle.from_degree_arcseconds(milliarcseconds / 1000.0)
      end

      def radial_velocity(kilometers_per_second)
        return unless kilometers_per_second

        Astronoby::Velocity.from_kilometers_per_second(kilometers_per_second)
      end
    end
  end
end
