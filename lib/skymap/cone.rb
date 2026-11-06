# frozen_string_literal: true

module Skymap
  Cone = Data.define(:center, :radius) do
    def initialize(center:, radius:)
      unless center.is_a?(Astronoby::Coordinates::Equatorial) &&
          center.epoch == Astronoby::JulianDate::J2000
        raise ArgumentError,
          "center must be Astronoby::Coordinates::Equatorial at J2000"
      end

      unless radius.is_a?(Astronoby::Angle) && radius.positive? &&
          radius.radians <= Math::PI
        raise ArgumentError,
          "radius must be an Astronoby::Angle above 0 and up to 180 degrees"
      end

      super
    end
  end
end
