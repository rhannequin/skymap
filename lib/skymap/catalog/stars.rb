# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class Stars
      include Enumerable

      PATH = File.expand_path("../../../data/stars.csv", __dir__)

      def each
        return enum_for(:each) unless block_given?

        CSV.foreach(PATH, headers: true) do |row|
          yield star_from(row)
        end
      end

      private

      def star_from(row)
        Star.new(
          hr: row["hr"].to_i,
          equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
            right_ascension: Astronoby::Angle.from_hours(
              row["right_ascension"].to_f
            ),
            declination: Astronoby::Angle.from_degrees(row["declination"].to_f),
            epoch: Astronoby::JulianDate::J2000
          ),
          magnitude: row["magnitude"].to_f,
          proper_motion_ra: proper_motion(row["proper_motion_ra"]),
          proper_motion_dec: proper_motion(row["proper_motion_dec"]),
          parallax: parallax(row["parallax"]),
          radial_velocity: radial_velocity(row["radial_velocity"])
        )
      end

      def proper_motion(value)
        return unless value

        Astronoby::AngularVelocity.from_milliarcseconds_per_year(value.to_i)
      end

      def parallax(value)
        return unless value

        Astronoby::Angle.from_degree_arcseconds(value.to_i / 1000.0)
      end

      def radial_velocity(value)
        return unless value

        Astronoby::Velocity.from_kilometers_per_second(value.to_i)
      end
    end
  end
end
