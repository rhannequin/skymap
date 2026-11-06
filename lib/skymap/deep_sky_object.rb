# frozen_string_literal: true

module Skymap
  DeepSkyObject = Data.define(
    :designation,
    :name,
    :type,
    :equatorial_coordinates,
    :magnitude,
    :major_axis,
    :minor_axis,
    :position_angle
  ) do
    def initialize(
      designation:,
      type:,
      equatorial_coordinates:,
      name: nil,
      magnitude: nil,
      major_axis: nil,
      minor_axis: nil,
      position_angle: nil
    )
      unless non_blank_string?(designation)
        raise ArgumentError, "designation must be a non-blank String"
      end

      unless name.nil? || non_blank_string?(name)
        raise ArgumentError, "name must be a non-blank String or nil"
      end

      unless DeepSkyObject::TYPES.include?(type)
        raise ArgumentError,
          "type must be one of #{DeepSkyObject::TYPES.join(", ")}"
      end

      unless equatorial_coordinates.is_a?(Astronoby::Coordinates::Equatorial) &&
          equatorial_coordinates.epoch == Astronoby::JulianDate::J2000
        raise ArgumentError,
          "equatorial_coordinates must be Astronoby::Coordinates::Equatorial " \
          "at J2000"
      end

      unless magnitude?(magnitude)
        raise ArgumentError, "magnitude must be a finite Numeric or nil"
      end

      unless axis?(major_axis)
        raise ArgumentError,
          "major_axis must be an Astronoby::Angle above 0 or nil"
      end

      unless axis?(minor_axis)
        raise ArgumentError,
          "minor_axis must be an Astronoby::Angle above 0 or nil"
      end

      if minor_axis && major_axis.nil?
        raise ArgumentError, "minor_axis must come with a major_axis"
      end

      if minor_axis && minor_axis > major_axis
        raise ArgumentError, "minor_axis must not be larger than major_axis"
      end

      unless position_angle?(position_angle)
        raise ArgumentError, "position_angle must be an Astronoby::Angle or nil"
      end

      super
    end

    def axes
      return if major_axis.nil?

      [major_axis, minor_axis || major_axis]
    end

    private

    def non_blank_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end

    def magnitude?(value)
      value.nil? ||
        (value.is_a?(Numeric) && value.real? && value.finite?)
    end

    def position_angle?(value)
      value.nil? ||
        (value.is_a?(Astronoby::Angle) && value.radians.finite?)
    end

    def axis?(value)
      value.nil? ||
        (value.is_a?(Astronoby::Angle) &&
          value.radians.finite? && value.positive?)
    end
  end

  DeepSkyObject::TYPES = %i[
    galaxy
    open_cluster
    globular_cluster
    planetary_nebula
    nebula
    supernova_remnant
    asterism
    double_star
    other
  ].freeze
end
