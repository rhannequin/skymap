# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class ConstellationNames
      PATH = File.expand_path(
        "../../../data/constellations/iau/names.csv",
        __dir__
      )

      def [](abbreviation)
        names[abbreviation]
      end

      private

      def names
        @names ||= CSV
          .read(PATH, headers: true, encoding: "UTF-8")
          .to_h { |row| [row["constellation"], row["name"]] }
      end
    end
  end
end
