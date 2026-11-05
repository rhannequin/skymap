# frozen_string_literal: true

module ThemeHelpers
  def theme_from_0_4_0
    Skymap::Theme.new(
      background: "none",
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
end

RSpec.configure do |config|
  config.include ThemeHelpers
end
