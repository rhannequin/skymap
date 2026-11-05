# frozen_string_literal: true

RSpec.describe Skymap::Layers::FieldCircles do
  describe "#elements" do
    it "draws a circle around the center of the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [5])

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)

      expect((left + right) / 2).to be_within(0.2).of(200)
      expect((top + bottom) / 2).to be_within(0.2).of(200)
    end

    it "gives the circle the true diameter of the field" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [5])

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)

      expect(right - left).to be_within(0.1).of(198.46)
      expect(bottom - top).to be_within(0.1).of(198.46)
    end

    it "draws one circle for each field, from the smallest to the largest" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [1, 2, 4])

      circles = layer.elements(context)
      widths = circles.map do |circle|
        left, right, = extent(circle.points)
        right - left
      end

      expect(circles.size).to eq(3)
      expect(widths).to eq(widths.sort)
    end

    it "closes the circle" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [1])

      circle, = layer.elements(context)

      expect(circle.points.first).to eq(circle.points.last)
    end

    it "draws a circle at its true size away from the center of the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 60)
      )
      center = horizontal(altitude: 65, azimuth: 180)
      layer = described_class.new(fields: [8], center: center)

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)
      above = project(context, altitude: 69, azimuth: 180)
      below = project(context, altitude: 61, azimuth: 180)

      expect(right - left).to be_within(0.3).of(bottom - top)
      expect(top).to be_within(0.3).of(above.y)
      expect(bottom).to be_within(0.3).of(below.y)
    end

    it "draws a circle around coordinates of the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 49, azimuth: 0, field_of_view: 30)
      )
      target = equatorial(right_ascension: 2.5, declination: 85)
      layer = described_class.new(fields: [2], center: target)

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)
      position = context.horizontal_coordinates(target)
      expected = project(
        context,
        altitude: position.altitude.degrees,
        azimuth: position.azimuth.degrees
      )

      expect((left + right) / 2).to be_within(0.3).of(expected.x)
      expect((top + bottom) / 2).to be_within(0.3).of(expected.y)
    end

    it "centers on the view when it is given equatorial coordinates" do
      target = equatorial(right_ascension: 2.5, declination: 85)
      view = Skymap::View.new(center: target, field_of_view: 10)
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      layer = described_class.new(fields: [2])

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)

      expect((left + right) / 2).to be_within(0.2).of(200)
      expect((top + bottom) / 2).to be_within(0.2).of(200)
    end

    it "uses fewer points for a small circle than for a large one" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [0.1, 5])

      small, large = layer.elements(context)

      expect(small.points.size).to be < large.points.size
      expect(large.points.size).to be < 200
    end

    it "keeps a very large circle to a reasonable number of points" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      center = horizontal(altitude: 60, azimuth: 120)
      layer = described_class.new(fields: [120], center: center)

      points = layer.elements(context).sum { |circle| circle.points.size }

      expect(points).to be <= 361
    end

    it "leaves out a circle that does not reach the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      far = horizontal(altitude: 40, azimuth: 0)
      layer = described_class.new(fields: [1, 5], center: far)

      circles = layer.elements(context)

      expect(circles).to be_empty
    end

    it "leaves out a circle that goes around the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 5)
      )
      layer = described_class.new(fields: [30])

      circles = layer.elements(context)

      expect(circles).to be_empty
    end

    it "keeps a circle that only crosses the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      edge = horizontal(altitude: 40, azimuth: 180 + 6.5)
      layer = described_class.new(fields: [4], center: edge)

      circles = layer.elements(context)

      expect(circles.size).to eq(1)
    end

    it "draws the part of a circle below the horizon in a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 1, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [4])

      circles = layer.elements(context)

      expect(circles.size).to eq(1)
      expect(circles.first.points.first).to eq(circles.first.points.last)
    end

    it "draws a thin line that scales with the canvas" do
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      layer = described_class.new(fields: [1])
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0),
        view: view
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0),
        view: view
      )

      small_circle, = layer.elements(small)
      large_circle, = layer.elements(large)

      expect(small_circle.width).to be < 1
      expect(large_circle.width).to eq(small_circle.width * 2)
    end

    it "draws a circle without labels by default" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [1, 2])

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions).to be_empty
    end

    it "writes the field of each circle in degrees with labels" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(
        fields: [4, 2.5, 0.25, 1.0833333],
        labels: true
      )

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions.map(&:text)).to eq(["4°", "2.5°", "0.25°", "1.1°"])
      expect(captions.map(&:kind).uniq).to eq([:field])
    end

    it "writes the label next to its circle" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [2], labels: true)

      circle, caption = layer.elements(context)
      left, right, = extent(circle.points)

      expect(distance_from_center(caption.position)).to be_within(1).of(
        (right - left) / 2 + caption.size
      )
    end

    it "writes the names it is given instead of the field" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(
        fields: [4, 2, 1],
        labels: true,
        names: {4 => "Finder"}
      )

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions.map(&:text)).to eq(["Finder", "2°", "1°"])
    end

    it "writes only the names it is given without labels" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [4, 2], names: {2 => "Eyepiece"})

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions.map(&:text)).to eq(["Eyepiece"])
    end

    it "leaves out the label of a circle that does not reach the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      far = horizontal(altitude: 40, azimuth: 0)
      layer = described_class.new(fields: [1], center: far, labels: true)

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "leaves out the label that would fall outside the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: [9.9], labels: true)

      elements = layer.elements(context)

      expect(elements.grep(Skymap::Renderer::FieldCircle).size).to eq(1)
      expect(elements.grep(Skymap::Renderer::Caption)).to be_empty
    end
  end

  describe "#elements without a view" do
    it "draws nothing without a center" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(fields: [5], labels: true)

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "draws a circle around the center it is given" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 60, azimuth: 90)
      layer = described_class.new(fields: [10], center: center)

      circle, = layer.elements(context)
      left, right, top, bottom = extent(circle.points)
      east = project(context, altitude: 60, azimuth: 90)

      expect(circle.points.first).to eq(circle.points.last)
      expect(bottom - top).to be_within(0.3).of(right - left)
      expect((left + right) / 2).to be_within(1).of(east.x)
      expect((top + bottom) / 2).to be_within(1).of(east.y)
    end

    it "stops a circle at the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 2, azimuth: 90)
      layer = described_class.new(fields: [10], center: center)

      circle, = layer.elements(context)
      distances = circle.points.map { |point| distance_from_center(point) }

      expect(distances.max).to be <= 198.5
      expect(circle.points.first).not_to eq(circle.points.last)
    end

    it "leaves out a circle below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: -40, azimuth: 90)
      layer = described_class.new(fields: [10], center: center, labels: true)

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "draws a circle around the zenith" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 90, azimuth: 0)
      layer = described_class.new(fields: [10], center: center)

      circle, = layer.elements(context)
      distances = circle.points.map { |point| distance_from_center(point) }

      expect(distances.max - distances.min).to be < 0.2
      expect(distances.max).to be_within(0.5).of(8.67)
    end
  end

  describe ".new" do
    it "rejects fields that are not a list" do
      expect { described_class.new(fields: 5) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects an empty list of fields" do
      expect { described_class.new(fields: []) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field of zero" do
      expect { described_class.new(fields: [1, 0]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a negative field" do
      expect { described_class.new(fields: [-1]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field above 180 degrees" do
      expect { described_class.new(fields: [181]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field that is not a number" do
      expect { described_class.new(fields: ["1"]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field that is not a real number" do
      expect { described_class.new(fields: [Float::NAN]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a center that is not a coordinates object" do
      expect { described_class.new(fields: [1], center: [5.6, 0]) }
        .to raise_error(ArgumentError, /center must be/)
    end
  end

  def horizontal(altitude:, azimuth:)
    Astronoby::Coordinates::Horizontal.new(
      altitude: Astronoby::Angle.from_degrees(altitude),
      azimuth: Astronoby::Angle.from_degrees(azimuth),
      observer: observer_at(latitude: 48.8575)
    )
  end

  def project(context, altitude:, azimuth:)
    context.project(
      altitude: Astronoby::Angle.from_degrees(altitude),
      azimuth: Astronoby::Angle.from_degrees(azimuth)
    )
  end

  def extent(points)
    xs = points.map(&:x)
    ys = points.map(&:y)

    [xs.min, xs.max, ys.min, ys.max]
  end
end
