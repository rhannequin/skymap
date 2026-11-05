# frozen_string_literal: true

module Skymap
  Eyepiece = Data.define(:focal_length, :apparent_field_of_view) do
    def initialize(focal_length:, apparent_field_of_view:)
      unless focal_length.is_a?(Numeric) && focal_length.real? &&
          focal_length.finite? && focal_length > 0
        raise ArgumentError,
          "focal_length must be a number of millimeters above 0"
      end

      unless apparent_field_of_view.is_a?(Numeric) &&
          apparent_field_of_view.real? && apparent_field_of_view > 0 &&
          apparent_field_of_view <= 180
        raise ArgumentError,
          "apparent_field_of_view must be a number of degrees " \
          "above 0 and up to 180"
      end

      super
    end
  end
end
