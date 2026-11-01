# frozen_string_literal: true

module Skymap
  Theme = Data.define(
    :sky,
    :horizon,
    :star,
    :constellation_line,
    :boundary,
    :ecliptic,
    :planet,
    :sun,
    :moon,
    :moon_shadow,
    :moon_shadow_opacity,
    :constellation_name,
    :star_name,
    :planet_name,
    :label,
    :font
  ) do
    def self.dark
      new(
        sky: "#000000",
        horizon: "#3262a8",
        star: "#ffffff",
        constellation_line: "#46689c",
        boundary: "#2b3f5e",
        ecliptic: "#8c7a3a",
        planet: "#ffe6b3",
        sun: "#ffd34d",
        moon: "#f1ecd6",
        moon_shadow: "#232a35",
        moon_shadow_opacity: 0.6,
        constellation_name: "#6f8fc2",
        star_name: "#a8b8d0",
        planet_name: "#ffe6b3",
        label: "#3262a8",
        font: "sans-serif"
      )
    end

    def self.light
      new(
        sky: "#ffffff",
        horizon: "#1f3f73",
        star: "#111111",
        constellation_line: "#5b7bb0",
        boundary: "#b8c4d9",
        ecliptic: "#b08d1f",
        planet: "#c2570c",
        sun: "#f0a500",
        moon: "#e8d27a",
        moon_shadow: "#3b4252",
        moon_shadow_opacity: 0.35,
        constellation_name: "#4a679a",
        star_name: "#3d4a60",
        planet_name: "#c2570c",
        label: "#1f3f73",
        font: "sans-serif"
      )
    end

    def self.night
      new(
        sky: "#000000",
        horizon: "#7a1010",
        star: "#ff6b6b",
        constellation_line: "#8a2020",
        boundary: "#4a1212",
        ecliptic: "#a33a1a",
        planet: "#ff9a7a",
        sun: "#ff8a3d",
        moon: "#ffb3a0",
        moon_shadow: "#2a0a0a",
        moon_shadow_opacity: 0.6,
        constellation_name: "#c24a4a",
        star_name: "#e08a8a",
        planet_name: "#ff9a7a",
        label: "#7a1010",
        font: "sans-serif"
      )
    end

    def initialize(**slots)
      slots.each do |slot, value|
        next if slot == :moon_shadow_opacity || value.is_a?(String)

        raise ArgumentError, "#{slot} must be a string"
      end

      opacity = slots[:moon_shadow_opacity]
      if slots.key?(:moon_shadow_opacity) &&
          !(opacity.is_a?(Numeric) && opacity.between?(0, 1))
        raise ArgumentError, "moon_shadow_opacity must be between 0 and 1"
      end

      super
    end
  end
end
