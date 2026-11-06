# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class DeepSkyObjects
      include Enumerable

      PATH = File.expand_path("../../../data/deep_sky_objects.csv", __dir__)
      MAGNITUDE_BANDS = {"V" => :visual, "B" => :blue}.freeze

      def each
        return enum_for(:each) unless block_given?

        CSV.foreach(PATH, headers: true) do |row|
          yield deep_sky_object_from(row)
        end
      end

      private

      def deep_sky_object_from(row)
        DeepSkyObject.new(
          designation: row["designation"],
          name: row["name"],
          type: row["type"].to_sym,
          equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
            right_ascension: Astronoby::Angle.from_hours(
              row["right_ascension"].to_f
            ),
            declination: Astronoby::Angle.from_degrees(row["declination"].to_f),
            epoch: Astronoby::JulianDate::J2000
          ),
          magnitude: row["magnitude"]&.to_f,
          magnitude_band: MAGNITUDE_BANDS[row["magnitude_band"]],
          major_axis: arcminutes(row["major_axis"]),
          minor_axis: arcminutes(row["minor_axis"]),
          position_angle: position_angle(row["position_angle"])
        )
      end

      def arcminutes(value)
        return unless value

        Astronoby::Angle.from_degrees(value.to_f / 60.0)
      end

      def position_angle(value)
        return unless value

        Astronoby::Angle.from_degrees(value.to_f)
      end
    end
  end
end
