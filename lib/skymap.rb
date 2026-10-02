# frozen_string_literal: true

require "astronoby"

require_relative "skymap/canvas"
require_relative "skymap/catalog/stars"
require_relative "skymap/chart"
require_relative "skymap/projection/stereographic"
require_relative "skymap/renderer/dot"
require_relative "skymap/renderer/label"
require_relative "skymap/renderer/svg"
require_relative "skymap/star"
require_relative "skymap/star_size"
require_relative "skymap/version"

module Skymap
  class Error < StandardError; end
end
