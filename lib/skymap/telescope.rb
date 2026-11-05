# frozen_string_literal: true

module Skymap
  Telescope = Data.define(:focal_length_mm, :aperture_mm) do
    def initialize(focal_length_mm:, aperture_mm:)
      {focal_length_mm: focal_length_mm, aperture_mm: aperture_mm}
        .each do |name, value|
          unless value.is_a?(Numeric) && value.real? && value.finite? &&
              value > 0
            raise ArgumentError, "#{name} must be a number above 0"
          end
        end

      super
    end
  end
end
