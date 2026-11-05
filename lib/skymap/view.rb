# frozen_string_literal: true

module Skymap
  View = Data.define(:center, :field_of_view) do
    def initialize(center:, field_of_view:)
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

      super
    end
  end
end
