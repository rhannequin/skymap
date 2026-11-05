# frozen_string_literal: true

module Skymap
  Setup = Data.define(:telescope, :eyepiece) do
    def initialize(telescope:, eyepiece:)
      unless telescope.is_a?(Telescope)
        raise ArgumentError, "telescope must be a Skymap::Telescope"
      end

      unless eyepiece.is_a?(Eyepiece)
        raise ArgumentError, "eyepiece must be a Skymap::Eyepiece"
      end

      super
    end

    def magnification
      telescope.focal_length_mm.fdiv(eyepiece.focal_length_mm)
    end

    def true_field
      Astronoby::Angle.from_degrees(
        eyepiece.apparent_field_of_view.degrees / magnification
      )
    end

    def label
      "#{plain(eyepiece.focal_length_mm.to_f)} mm, " \
        "#{magnification.round}×, #{plain_angle(true_field)}"
    end

    private

    def plain_angle(angle)
      minutes = angle.degrees * 60
      return "#{plain(angle.degrees.round(1))}°" if minutes.round >= 60
      return "#{minutes.round}′" if minutes.round >= 1

      "#{(minutes * 60).round}″"
    end

    def plain(number)
      number.to_s.delete_suffix(".0")
    end
  end
end
