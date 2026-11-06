# frozen_string_literal: true

module Skymap
  class StarList
    def self.wrap(stars)
      return stars if stars.respond_to?(:search)

      new(stars)
    end

    def initialize(stars)
      @stars = stars
    end

    def search(magnitude_limit: nil, cone: nil)
      return @stars.to_a unless magnitude_limit

      @stars.select { |star| star.magnitude <= magnitude_limit }
    end

    def by_hr
      Star.by_hr(@stars)
    end
  end
end
