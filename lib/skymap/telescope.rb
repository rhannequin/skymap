# frozen_string_literal: true

module Skymap
  Telescope = Data.define(:focal_length, :aperture) do
    def initialize(focal_length:, aperture:)
      {focal_length: focal_length, aperture: aperture}.each do |name, value|
        unless value.is_a?(Numeric) && value.real? && value.finite? &&
            value > 0
          raise ArgumentError,
            "#{name} must be a number of millimeters above 0"
        end
      end

      super
    end

    def magnification(eyepiece)
      check_eyepiece(eyepiece)

      focal_length.fdiv(eyepiece.focal_length)
    end

    def true_field(eyepiece)
      magnification = magnification(eyepiece)

      eyepiece.apparent_field_of_view.fdiv(magnification)
    end

    private

    def check_eyepiece(eyepiece)
      return if eyepiece.is_a?(Eyepiece)

      raise ArgumentError, "eyepiece must be a Skymap::Eyepiece"
    end
  end
end
