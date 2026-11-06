# frozen_string_literal: true

RSpec.describe Skymap::Layers::DeepSkyObjects do
  def canvas
    Skymap::Canvas.new(size: 800, padding: 24)
  end

  def view_on(object, field_of_view, **options)
    Skymap::View.new(
      center: object.equatorial_coordinates,
      field_of_view: Astronoby::Angle.from_degrees(field_of_view),
      **options
    )
  end

  def context_for(view = nil)
    context_at(latitude: 48.8575, canvas: canvas, view: view)
  end

  def center_of(context, object)
    horizontal = context.horizontal_coordinates(object.equatorial_coordinates)

    context.project(
      altitude: horizontal.altitude,
      azimuth: horizontal.azimuth
    )
  end

  def degrees_between(first, second)
    (((first - second) + 180) % 360 - 180).abs
  end

  describe "DEFAULT_MAGNITUDE_LIMIT" do
    it "keeps every Messier object" do
      faintest = Skymap::Catalog::DeepSkyObjects.new.filter_map(&:magnitude).max

      expect(described_class::DEFAULT_MAGNITUDE_LIMIT).to be >= faintest
    end
  end

  describe "#elements" do
    it "draws an object where it is in the sky" do
      object = deep_sky_object
      context = context_for
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context)
      expected = center_of(context, object)

      expect(symbol.center.x).to be_within(1e-9).of(expected.x)
      expect(symbol.center.y).to be_within(1e-9).of(expected.y)
    end

    it "draws the symbol of the type of the object" do
      objects = Skymap::DeepSkyObject::TYPES.map do |type|
        deep_sky_object(type: type)
      end
      layer = described_class.new(objects: objects)

      symbols = layer.elements(context_for)

      expect(symbols.map(&:kind)).to eq(Skymap::DeepSkyObject::TYPES)
    end

    it "draws nothing for no objects" do
      layer = described_class.new(objects: [])

      expect(layer.elements(context_for)).to eq([])
    end

    it "draws the objects of any enumerable of objects" do
      catalog = Skymap::Catalog::DeepSkyObjects.new
      layer = described_class.new(objects: catalog)

      symbols = layer.elements(context_for)

      expect(symbols).not_to be_empty
    end

    it "draws the lines relative to the radius of the canvas" do
      small = Skymap::Canvas.new(size: 400, padding: 0)
      large = Skymap::Canvas.new(size: 800, padding: 0)
      layer = described_class.new(objects: [deep_sky_object])

      small_symbol, = layer.elements(context_at(latitude: 48.8575,
        canvas: small))
      large_symbol, = layer.elements(context_at(latitude: 48.8575,
        canvas: large))

      expect(large_symbol.width).to eq(2 * small_symbol.width)
      expect(large_symbol.width).to eq(0.003 * 400)
    end
  end

  describe "#elements with a magnitude limit" do
    it "leaves out an object fainter than the limit" do
      objects = [deep_sky_object(magnitude: 11.5)]
      layer = described_class.new(objects: objects, magnitude_limit: 11)

      expect(layer.elements(context_for)).to be_empty
    end

    it "draws an object as bright as the limit" do
      objects = [deep_sky_object(magnitude: 9)]
      layer = described_class.new(objects: objects, magnitude_limit: 9)

      expect(layer.elements(context_for).size).to eq(1)
    end

    it "draws an object without a magnitude" do
      layer = described_class.new(objects: [deep_sky_object],
        magnitude_limit: 1)

      expect(layer.elements(context_for).size).to eq(1)
    end

    it "draws an object as faint as the faintest Messier object by default" do
      faintest = Skymap::Catalog::DeepSkyObjects.new.filter_map(&:magnitude).max
      layer = described_class.new(
        objects: [deep_sky_object(magnitude: faintest)]
      )

      expect(layer.elements(context_for).size).to eq(1)
    end
  end

  describe "#elements below the horizon" do
    it "leaves out an object below the horizon of the whole sky" do
      object = deep_sky_object(declination: -80)
      layer = described_class.new(objects: [object])

      expect(layer.elements(context_for)).to be_empty
    end

    it "leaves out an object below the horizon of a view" do
      object = deep_sky_object(declination: -80)
      layer = described_class.new(objects: [object])

      expect(layer.elements(context_for(view_on(object, 20)))).to be_empty
    end
  end

  describe "#elements in a view" do
    it "leaves out an object outside the view" do
      object = deep_sky_object
      far = deep_sky_object(right_ascension: 21.0, declination: 50)
      layer = described_class.new(objects: [far])

      expect(layer.elements(context_for(view_on(object, 4)))).to be_empty
    end

    it "draws an object inside the view" do
      object = deep_sky_object
      layer = described_class.new(objects: [object])

      expect(layer.elements(context_for(view_on(object, 4))).size).to eq(1)
    end

    it "draws an object just outside the view when its size reaches in" do
      center = deep_sky_object
      nearby = deep_sky_object(
        right_ascension: 21.0,
        declination: 31.5 + 2.2,
        major: 1.5
      )
      small = deep_sky_object(right_ascension: 21.0, declination: 31.5 + 2.2)

      large = described_class.new(objects: [nearby])
      point = described_class.new(objects: [small])
      context = context_for(view_on(center, 4))

      expect(large.elements(context).size).to eq(1)
      expect(point.elements(context)).to be_empty
    end
  end

  describe "#elements for the size of an object" do
    it "draws a circle of the minimum size when the size is unknown" do
      layer = described_class.new(objects: [deep_sky_object])

      symbol, = layer.elements(context_for)

      expect(symbol.semi_major).to be_within(1e-9).of(0.012 * 376)
      expect(symbol.semi_minor).to eq(symbol.semi_major)
      expect(symbol.rotation).to eq(0)
    end

    it "draws the minimum size for an object that is smaller on the map" do
      object = deep_sky_object(major: 0.01)
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context_for)

      expect(symbol.semi_major).to be_within(1e-9).of(0.012 * 376)
    end

    it "draws an object at its real size once that is larger" do
      object = deep_sky_object(major: 1.0)
      context = context_for(view_on(object, 4))
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context)
      horizontal = context.horizontal_coordinates(object.equatorial_coordinates)
      expected = context.span(
        object.major_axis,
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      ) / 2

      expect(symbol.semi_major).to be_within(1e-9).of(expected)
      expect(symbol.semi_major).to be > 0.012 * 376
    end

    it "draws 1 degree across a quarter of a view of 4 degrees" do
      object = deep_sky_object(major: 1.0)
      context = context_for(view_on(object, 4))
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context)

      expect(2 * symbol.semi_major).to be_within(1).of(2 * 376 / 4.0)
    end

    it "keeps the proportions of an object grown to the minimum size" do
      object = deep_sky_object(major: 0.01, minor: 0.005, position_angle: 30)
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context_for)

      expect(symbol.semi_major).to be_within(1e-9).of(0.012 * 376)
      expect(symbol.semi_minor).to be_within(1e-9).of(0.006 * 376)
    end

    it "draws the proportions of an elongated object with a position angle" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 30)
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context_for(view_on(object, 6)))

      expect(symbol.semi_major / symbol.semi_minor).to be_within(1e-6).of(4)
    end

    it "draws a circle of the same area without a position angle" do
      object = deep_sky_object(major: 2.0, minor: 0.5)
      round = deep_sky_object(major: 1.0)
      context = context_for(view_on(object, 6))

      symbol, = described_class.new(objects: [object]).elements(context)
      expected, = described_class.new(objects: [round]).elements(context)

      expect(symbol.semi_major).to be_within(1e-9).of(expected.semi_major)
      expect(symbol.semi_minor).to eq(symbol.semi_major)
      expect(symbol.rotation).to eq(0)
    end

    it "draws a circle for a round object, whatever its position angle" do
      object = deep_sky_object(major: 1.0, position_angle: 50)
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context_for(view_on(object, 4)))

      expect(symbol.semi_minor).to eq(symbol.semi_major)
      expect(symbol.rotation).to eq(0)
    end

    it "draws a circle for an object with equal axes" do
      object = deep_sky_object(major: 1.0, minor: 1.0, position_angle: 50)
      layer = described_class.new(objects: [object])

      symbol, = layer.elements(context_for(view_on(object, 4)))

      expect(symbol.semi_minor).to eq(symbol.semi_major)
      expect(symbol.rotation).to eq(0)
    end
  end

  describe "#elements for the orientation of an object" do
    def rotation_of(object, view)
      context = context_for(view)
      symbol, = described_class.new(objects: [object]).elements(context)

      [symbol.rotation, context]
    end

    it "turns an elongated object with its position angle on the map" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 35)
      view = view_on(object, 6, orientation: :equatorial)

      rotation, context = rotation_of(object, view)
      expected = context.rotation_at(
        object.equatorial_coordinates,
        position_angle: object.position_angle
      )

      expect(rotation).to be_within(1e-9).of(expected.degrees)
    end

    it "puts the major axis toward the north, up in an equatorial view" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 0)
      view = view_on(object, 6, orientation: :equatorial)

      rotation, = rotation_of(object, view)

      expect(degrees_between(rotation, -90)).to be < 0.5
    end

    it "puts the major axis toward the east, left in an equatorial view" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 90)
      view = view_on(object, 6, orientation: :equatorial)

      rotation, = rotation_of(object, view)

      expect(degrees_between(rotation, 180)).to be < 0.5
    end

    it "turns the object with the rotation of the view" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 35)
      upright, = rotation_of(
        object, view_on(object, 6, orientation: :equatorial)
      )
      turned, = rotation_of(
        object,
        view_on(
          object,
          6,
          orientation: :equatorial,
          rotation: Astronoby::Angle.from_degrees(40)
        )
      )

      expect(degrees_between(turned - upright, 40)).to be < 1e-6
    end

    it "turns the object the other way in a mirrored view" do
      object = deep_sky_object(major: 2.0, minor: 0.5, position_angle: 35)
      upright, = rotation_of(
        object, view_on(object, 6, orientation: :equatorial)
      )
      mirrored, = rotation_of(
        object, view_on(object, 6, orientation: :equatorial, mirrored: true)
      )

      expect(degrees_between(upright + mirrored, -180)).to be < 1e-6
    end

    it "follows the sky in the whole sky" do
      object = deep_sky_object(major: 20.0, minor: 5.0, position_angle: 35)

      rotation, context = rotation_of(object, nil)
      expected = context.rotation_at(
        object.equatorial_coordinates,
        position_angle: object.position_angle
      )

      expect(rotation).to be_within(1e-9).of(expected.degrees)
    end
  end

  describe "#elements with labels" do
    it "draws no label by default" do
      layer = described_class.new(objects: [deep_sky_object])

      elements = layer.elements(context_for)

      expect(elements.map(&:class)).to eq([Skymap::Renderer::DeepSkySymbol])
    end

    it "writes the designation next to the symbol" do
      object = deep_sky_object(designation: "M99")
      layer = described_class.new(objects: [object], labels: true)

      symbol, caption = layer.elements(context_for)

      expect(caption).to be_a(Skymap::Renderer::Caption)
      expect(caption.text).to eq("M99")
      expect(caption.kind).to eq(:deep_sky)
      expect(caption.position.x).to be_within(1).of(symbol.center.x)
      expect((caption.position.y - symbol.center.y).abs)
        .to be > symbol.semi_major
    end

    it "keeps the label out of the symbol of a large object" do
      object = deep_sky_object(major: 1.0)
      layer = described_class.new(objects: [object], labels: true)

      symbol, caption = layer.elements(context_for(view_on(object, 4)))

      expect((caption.position.y - symbol.center.y).abs)
        .to be > symbol.semi_major
    end

    it "labels only the objects that are drawn" do
      objects = [
        deep_sky_object(designation: "M1", magnitude: 5),
        deep_sky_object(designation: "M2", magnitude: 15)
      ]
      layer = described_class.new(objects: objects, labels: true)

      captions = layer.elements(context_for).grep(Skymap::Renderer::Caption)

      expect(captions.map(&:text)).to eq(["M1"])
    end
  end
end
