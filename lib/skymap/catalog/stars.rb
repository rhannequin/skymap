# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class Stars
      include Enumerable

      PATH = File.expand_path("../../../data/stars.csv", __dir__)

      def each
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
          magnitude: row["magnitude"].to_f
        )
      end
    end
  end
end
