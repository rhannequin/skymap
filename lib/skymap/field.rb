# frozen_string_literal: true

module Skymap
  Field = Data.define(:true_field, :label) do
    def initialize(true_field:, label:)
      unless true_field.is_a?(Astronoby::Angle) && true_field.positive? &&
          true_field.radians <= Math::PI
        raise ArgumentError,
          "true_field must be an Astronoby::Angle " \
          "above 0 and up to 180 degrees"
      end

      unless label.is_a?(String) && !label.strip.empty?
        raise ArgumentError, "label must be a string that is not blank"
      end

      super
    end
  end
end
