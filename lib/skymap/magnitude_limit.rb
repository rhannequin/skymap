# frozen_string_literal: true

module Skymap
  module MagnitudeLimit
    module_function

    def check(value, name: :magnitude_limit, allow_nil: false)
      return if allow_nil && value.nil?
      return if value.is_a?(Numeric) && value.real? && value.finite?

      raise ArgumentError,
        "#{name} must be a finite Numeric#{" or nil" if allow_nil}"
    end
  end
end
