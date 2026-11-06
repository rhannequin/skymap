# frozen_string_literal: true

RSpec.describe Skymap::Layers::FieldCircles do
  describe "#elements" do
    it "draws a circle around the center of the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: fields_of(5))

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
      layer = described_class.new(fields: fields_of(5))

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
      layer = described_class.new(fields: fields_of(1, 2, 4))

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
      layer = described_class.new(fields: fields_of(1))

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
      layer = described_class.new(fields: fields_of(8), center: center)

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
      layer = described_class.new(fields: fields_of(2), center: target)

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
      view = Skymap::View.new(
        center: target,
        field_of_view: Astronoby::Angle.from_degrees(10)
      )
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      layer = described_class.new(fields: fields_of(2))

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
      layer = described_class.new(fields: fields_of(0.1, 5))

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
      layer = described_class.new(fields: fields_of(120), center: center)

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
      layer = described_class.new(fields: fields_of(1, 5), center: far)

      circles = layer.elements(context)

      expect(circles).to be_empty
    end

    it "leaves out a circle that goes around the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 5)
      )
      layer = described_class.new(fields: fields_of(30))

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
      layer = described_class.new(fields: fields_of(4), center: edge)

      circles = layer.elements(context)

      expect(circles.size).to eq(1)
    end

    it "draws the part of a circle below the horizon in a view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 1, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: fields_of(4))

      circles = layer.elements(context)

      expect(circles.size).to eq(1)
      expect(circles.first.points.first).to eq(circles.first.points.last)
    end

    it "draws a thin line that scales with the canvas" do
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      layer = described_class.new(fields: fields_of(1))
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
      layer = described_class.new(fields: fields_of(1, 2))

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions).to be_empty
    end

    it "writes the label of each field when asked to" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(
        fields: [
          field_of(4, "Finder"),
          field_of(2, "Eyepiece"),
          field_of(1, "Telrad")
        ],
        labels: true
      )

      captions = layer.elements(context).grep(Skymap::Renderer::Caption)

      expect(captions.map(&:text)).to eq(%w[Finder Eyepiece Telrad])
      expect(captions.map(&:kind).uniq).to eq([:field])
    end

    it "draws the true field and the label of a setup" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      setup = Skymap::Setup.new(
        telescope: Skymap::Telescope.new(
          focal_length_mm: 1200,
          aperture_mm: 200
        ),
        eyepiece: Skymap::Eyepiece.new(
          focal_length_mm: 25,
          apparent_field_of_view: Astronoby::Angle.from_degrees(52)
        )
      )
      layer = described_class.new(fields: [setup], labels: true)

      circle, caption = layer.elements(context)
      left, right, = extent(circle.points)

      expect(caption.text).to eq("25 mm, 48×, 1.1°")
      expect(right - left).to be_within(0.2).of(198.5 * 1.0833 / 5)
    end

    it "writes the label next to its circle" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: fields_of(2), labels: true)

      circle, caption = layer.elements(context)
      left, right, = extent(circle.points)

      expect(distance_from_center(caption.position)).to be_within(1).of(
        (right - left) / 2 + caption.size
      )
    end

    it "anchors the label to its circle" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: fields_of(2), labels: true)

      circle, caption = layer.elements(context)
      left, right, top, bottom = extent(circle.points)

      expect(caption.anchor.x).to be_within(1e-6).of((left + right) / 2)
      expect(caption.anchor.y).to be_within(1e-6).of((top + bottom) / 2)
      expect(caption.clearance).to be_within(1e-6).of((bottom - top) / 2)
    end

    it "leaves out the label of a circle that does not reach the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      far = horizontal(altitude: 40, azimuth: 0)
      layer = described_class.new(
        fields: fields_of(1),
        center: far,
        labels: true
      )

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "leaves out the label that would fall outside the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 40, azimuth: 180, field_of_view: 10)
      )
      layer = described_class.new(fields: fields_of(9.9), labels: true)

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
      layer = described_class.new(fields: fields_of(5), labels: true)

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "draws a circle around the center it is given" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 60, azimuth: 90)
      layer = described_class.new(fields: fields_of(10), center: center)

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
      layer = described_class.new(fields: fields_of(10), center: center)

      circle, = layer.elements(context)
      distances = circle.points.map { |point| distance_from_center(point) }

      expect(distances.max).to be <= 198.5
      expect(circle.points.first).not_to eq(circle.points.last)
    end

    it "draws a circle up to the horizon where it crosses it" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 5, azimuth: 90)
      layer = described_class.new(fields: fields_of(20), center: center)

      circle, = layer.elements(context)

      expect(distance_from_center(circle.points.first)).to be_within(0.01)
        .of(198.5)
      expect(distance_from_center(circle.points.last)).to be_within(0.01)
        .of(198.5)
    end

    it "leaves out a circle around the nadir" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      nadir = horizontal(altitude: -90, azimuth: 0)
      layer = described_class.new(
        fields: fields_of(10),
        center: nadir,
        labels: true
      )

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "leaves out a circle just above the nadir" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      near_nadir = horizontal(altitude: -89.99, azimuth: 0)
      layer = described_class.new(fields: fields_of(10), center: near_nadir)

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "draws a circle that reaches the horizon from just under it" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: -1, azimuth: 0)
      layer = described_class.new(fields: fields_of(10), center: center)

      circle, = layer.elements(context)

      expect(circle.points.size).to be <= 361
      expect(distance_from_center(circle.points.first)).to be_within(0.01)
        .of(198.5)
    end

    it "leaves out a circle below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: -40, azimuth: 90)
      layer = described_class.new(
        fields: fields_of(10),
        center: center,
        labels: true
      )

      elements = layer.elements(context)

      expect(elements).to be_empty
    end

    it "draws a circle around the zenith" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      center = horizontal(altitude: 90, azimuth: 0)
      layer = described_class.new(fields: fields_of(10), center: center)

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

    it "rejects a field that is a number" do
      expect { described_class.new(fields: [5]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field without a label" do
      field = Struct.new(:true_field).new(angle(5))

      expect { described_class.new(fields: [field]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a field with a label that is not a string" do
      expect { described_class.new(fields: [loose_field(angle(5), 5)]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a true field that is not an angle" do
      expect { described_class.new(fields: [loose_field(5, "5°")]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a true field of zero" do
      expect { described_class.new(fields: [loose_field(angle(0), "0°")]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a negative true field" do
      expect { described_class.new(fields: [loose_field(angle(-1), "-1°")]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a true field above 180 degrees" do
      expect { described_class.new(fields: [loose_field(angle(181), "181°")]) }
        .to raise_error(ArgumentError, /fields must be/)
    end

    it "rejects a center that is not a coordinates object" do
      expect { described_class.new(fields: fields_of(1), center: [5.6, 0]) }
        .to raise_error(ArgumentError, /center must be/)
    end
  end

  def fields_of(*degrees)
    degrees.map { |value| field_of(value, "#{value}°") }
  end

  def field_of(degrees, label)
    Skymap::Field.new(true_field: angle(degrees), label: label)
  end

  def loose_field(true_field, label)
    Struct.new(:true_field, :label).new(true_field, label)
  end

  def angle(degrees)
    Astronoby::Angle.from_degrees(degrees)
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
