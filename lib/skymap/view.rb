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
      rotation: Astronoby::Angle.zero,
      mirrored: false
    )
      unless center.is_a?(Astronoby::Coordinates::Equatorial) ||
          center.is_a?(Astronoby::Coordinates::Horizontal)
        raise ArgumentError,
          "center must be equatorial or horizontal coordinates"
      end

      unless field_of_view.is_a?(Astronoby::Angle) &&
          field_of_view.positive? && field_of_view.radians <= Math::PI
        raise ArgumentError,
          "field_of_view must be an Astronoby::Angle " \
          "above 0 and up to 180 degrees"
      end

      unless View::ORIENTATIONS.include?(orientation)
        raise ArgumentError,
          "orientation must be one of #{View::ORIENTATIONS.join(", ")}"
      end

      unless rotation.is_a?(Astronoby::Angle) && rotation.radians.finite?
        raise ArgumentError, "rotation must be an Astronoby::Angle"
      end

      unless [true, false].include?(mirrored)
        raise ArgumentError, "mirrored must be true or false"
      end

      super
    end
  end

  View::ORIENTATIONS = %i[zenith_up equatorial].freeze
end
