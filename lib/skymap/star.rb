# frozen_string_literal: true

module Skymap
  Star = Data.define(:hr, :equatorial_coordinates, :magnitude) do
    def self.by_hr(stars)
      stars.to_h { |star| [star.hr, star] }
    end
  end
end
