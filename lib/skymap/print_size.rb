# frozen_string_literal: true

module Skymap
  PRINT_UNITS = %i[mm cm in].freeze
  PAPER_SHORT_SIDES_IN_MILLIMETERS = {
    a5: 148,
    a4: 210,
    a3: 297,
    letter: 215.9,
    tabloid: 279.4
  }.freeze
  DEFAULT_PAPER_MARGIN_IN_MILLIMETERS = 10

  PrintSize = Data.define(:length, :unit) do
    def self.paper(name, margin: DEFAULT_PAPER_MARGIN_IN_MILLIMETERS)
      short_side = PAPER_SHORT_SIDES_IN_MILLIMETERS.fetch(name) do
        papers = PAPER_SHORT_SIDES_IN_MILLIMETERS.keys.join(", ")
        raise ArgumentError, "paper must be one of #{papers}"
      end
      unless margin.is_a?(Numeric) && margin.real? && margin >= 0 &&
          margin < short_side / 2.0
        raise ArgumentError,
          "margin must not be negative and must be less than half the paper"
      end

      new(length: (short_side - 2 * margin).round(2), unit: :mm)
    end

    def initialize(length:, unit:)
      unless length.is_a?(Numeric) && length.real? && length.finite? &&
          length > 0
        raise ArgumentError, "length must be a number above 0"
      end

      unless PRINT_UNITS.include?(unit)
        raise ArgumentError, "unit must be one of #{PRINT_UNITS.join(", ")}"
      end

      super
    end

    def to_s
      number = length.to_f
      number = number.to_i if number == number.to_i

      "#{number}#{unit}"
    end
  end
end
