# frozen_string_literal: true

module Skymap
  module Renderer
    DeepSkySymbol = Data.define(
      :center,
      :kind,
      :semi_major,
      :semi_minor,
      :rotation,
      :width
    )
  end
end
