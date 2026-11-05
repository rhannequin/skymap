# frozen_string_literal: true

module Skymap
  View = Data.define(
    :center,
    :field_of_view,
    :orientation,
    :rotation,
    :mirrored
  ) do
    def initialize(
      center:,
      field_of_view:,
      orientation: :zenith_up,
      rotation: 0,
      mirrored: false
    )
      unless center.is_a?(Astronoby::Coordinates::Equatorial) ||
          center.is_a?(Astronoby::Coordinates::Horizontal)
        raise ArgumentError,
          "center must be equatorial or horizontal coordinates"
      end

      unless field_of_view.is_a?(Numeric) && field_of_view.real? &&
          field_of_view > 0 && field_of_view <= 180
        raise ArgumentError,
          "field_of_view must be a number of degrees " \
          "above 0 and up to 180"
      end

      unless View::ORIENTATIONS.include?(orientation)
        raise ArgumentError,
          "orientation must be one of #{View::ORIENTATIONS.join(", ")}"
      end

      unless rotation.is_a?(Numeric) && rotation.real? && rotation.finite?
        raise ArgumentError, "rotation must be a number of degrees"
      end

      unless [true, false].include?(mirrored)
        raise ArgumentError, "mirrored must be true or false"
      end

      super
    end
  end

  View::ORIENTATIONS = %i[zenith_up equatorial].freeze
end
