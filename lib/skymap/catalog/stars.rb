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

        self.class.send(:records).each { |record| yield star_from(record) }
      end

      def search(magnitude_limit: nil, cone: nil)
        return whole_sky(magnitude_limit) unless cone

        read(magnitude_limit, cone)
      end

      def by_hr
        @by_hr ||= Star.by_hr(
          self.class.send(:records).each_with_hr.map { |record|
            star_from(record)
          }
        )
      end

      private

      def whole_sky(magnitude_limit)
        @whole_sky ||= {}
        @whole_sky[magnitude_limit] ||= read(magnitude_limit, nil).freeze
      end

      def read(magnitude_limit, cone)
        self.class.send(:records).each(
          magnitude_limit: magnitude_limit,
          center: cone && [
            cone.center.right_ascension.degrees,
            cone.center.declination.degrees
          ],
          radius: cone&.radius&.degrees
        ).map { |record| star_from(record) }
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
