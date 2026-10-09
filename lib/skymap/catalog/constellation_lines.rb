# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class ConstellationLines
      include Enumerable

      PATH = File.expand_path(
        "../../../data/constellations/iau/lines.csv",
        __dir__
      )

      def each
        CSV.foreach(PATH, headers: true) do |row|
          yield line_from(row)
        end
      end

      private

      def line_from(row)
        ConstellationLine.new(
          constellation: row["constellation"],
          from: hr_numbers(row["from_hr"]),
          to: hr_numbers(row["to_hr"]),
          weight: row["weight"].to_sym
        )
      end

      def hr_numbers(value)
        value.split.map(&:to_i)
      end
    end
  end
end
