# frozen_string_literal: true

require "csv"

module Skymap
  module Catalog
    class StarNames
      PATH = File.expand_path("../../../data/star_names.csv", __dir__)

      def [](hr)
        names[hr]
      end

      private

      def names
        @names ||= CSV
          .read(PATH, headers: true, encoding: "UTF-8")
          .to_h { |row| [row["hr"].to_i, row["name"]] }
      end
    end
  end
end
