# frozen_string_literal: true

module GeometryHelpers
  def distance_from_center(point)
    Math.hypot(point.x - 200, point.y - 200).round(2)
  end
end

RSpec.configure do |config|
  config.include GeometryHelpers
end
