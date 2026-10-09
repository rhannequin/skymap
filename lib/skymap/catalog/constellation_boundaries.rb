# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class ConstellationBoundaries
      include Enumerable

      PATH = File.expand_path(
        "../../../data/constellations/iau/boundaries.csv",
        __dir__
      )

      def each
        CSV.foreach(PATH, headers: true).chunk_while do |previous, row|
          previous["border"] == row["border"]
        end.each do |rows|
          yield boundary_from(rows)
        end
      end

      private

      def boundary_from(rows)
        ConstellationBoundary.new(
          constellations: rows.first["constellations"].split,
          points: rows.map { |row| coordinates_from(row) }
        )
      end

      def coordinates_from(row)
        Astronoby::Coordinates::Equatorial.new(
          right_ascension: Astronoby::Angle.from_hours(
            row["right_ascension"].to_f
          ),
          declination: Astronoby::Angle.from_degrees(row["declination"].to_f),
          epoch: Astronoby::JulianDate::J2000
        )
      end
    end
  end
end
