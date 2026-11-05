# frozen_string_literal: true

module Skymap
  Eyepiece = Data.define(:focal_length_mm, :apparent_field_of_view) do
    def initialize(focal_length_mm:, apparent_field_of_view:)
      unless focal_length_mm.is_a?(Numeric) && focal_length_mm.real? &&
          focal_length_mm.finite? && focal_length_mm > 0
        raise ArgumentError, "focal_length_mm must be a number above 0"
      end

      unless apparent_field_of_view.is_a?(Astronoby::Angle) &&
          apparent_field_of_view.positive? &&
          apparent_field_of_view.radians <= Math::PI
        raise ArgumentError,
          "apparent_field_of_view must be an Astronoby::Angle " \
          "above 0 and up to 180 degrees"
      end

      super
    end
  end
end
