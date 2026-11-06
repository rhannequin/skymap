# frozen_string_literal: true

module GeometryHelpers
  def distance_from_center(point)
    Math.hypot(point.x - 200, point.y - 200).round(2)
  end

  def separation_in_degrees(from, to)
    directions = [from, to].map do |coordinates|
      Skymap::Geometry.direction(
        coordinates.right_ascension.radians,
        coordinates.declination.radians
      )
    end

    Math.acos(Skymap::Geometry.dot(*directions).clamp(-1, 1)) * 180 / Math::PI
  end

  def sky_angle_between(from, to, canvas:, field_of_view:)
    scale = canvas.radius / (2 * Math.tan(field_of_view * Math::PI / 720))
    directions = [from, to].map do |point|
      x = point.x - canvas.center.x
      y = canvas.center.y - point.y
      squared = x**2 + y**2
      divisor = 4 * scale**2 + squared

      [4 * scale * x, 4 * scale * y, 4 * scale**2 - squared].map do |component|
        component / divisor
      end
    end
    cosine = directions.transpose.sum { |a, b| a * b }

    Math.acos(cosine.clamp(-1, 1)) * 180 / Math::PI
  end
end

RSpec.configure do |config|
  config.include GeometryHelpers
end
