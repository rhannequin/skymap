# frozen_string_literal: true

RSpec.describe Skymap::Layers::Scale do
  describe "#elements" do
    it "draws nothing on the whole sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      expect(layer.elements(context)).to eq([])
    end

    it "labels the largest round length that fits in a fifth of the map" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      layer = described_class.new
      fields = [180, 50, 20, 3, 1, 0.5, 0.2, 0.05, 0.01, 0.005]

      labels = fields.map do |field_of_view|
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view_towards(
            altitude: 45, azimuth: 180, field_of_view: field_of_view
          )
        )
        layer.elements(context).grep(Skymap::Renderer::Caption).first.text
      end

      expect(labels).to eq(%w[20° 5° 2° 30′ 10′ 5′ 2′ 30″ 5″ 2″])
    end

    it "draws a bar as long as the angle it says" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 45, azimuth: 180, field_of_view: 20)
      )
      layer = described_class.new

      bar = layer.elements(context).grep(Skymap::Renderer::ScaleBar).first

      expect(bar.to.x - bar.from.x).to be_within(0.05).of(39.82)
      expect(bar.to.y).to eq(bar.from.y)
    end

    it "draws a bar as long as the angle it says where it is drawn" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      layer = described_class.new
      degrees = {"°" => 1.0, "′" => 1 / 60.0, "″" => 1 / 3600.0}

      errors = [180, 150, 120, 90, 45, 10, 1].map do |field_of_view|
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view_towards(
            altitude: 0, azimuth: 180, field_of_view: field_of_view
          )
        )
        bar, caption = layer.elements(context)
        step, symbol = caption.text.match(/(\d+)(\D)/).captures
        angle = sky_angle_between(
          bar.from, bar.to, canvas: canvas, field_of_view: field_of_view
        )

        (angle / (step.to_i * degrees.fetch(symbol)) - 1).abs
      end

      expect(errors.max).to be < 0.005
    end

    it "keeps the bar under a fifth of the map width" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      layer = described_class.new

      lengths = [180, 90, 30, 10, 3, 1, 0.3, 0.1, 0.03].map do |field_of_view|
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view_towards(
            altitude: 45, azimuth: 180, field_of_view: field_of_view
          )
        )
        bar = layer.elements(context).grep(Skymap::Renderer::ScaleBar).first
        bar.to.x - bar.from.x
      end

      expect(lengths).to all(be_between(0.1 * 2 * 198.5, 0.2 * 2 * 198.5))
    end

    it "draws nothing when the field is too small for any length" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 45, azimuth: 180, field_of_view: 0.001)
      )
      layer = described_class.new

      expect(layer.elements(context)).to eq([])
    end

    it "sizes the bar for an equatorial view" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      layer = described_class.new
      view = Skymap::View.new(
        center: equatorial(right_ascension: 5.6, declination: 0),
        field_of_view: 20
      )
      context = context_at(latitude: 48.8575, canvas: canvas, view: view)

      bar = layer.elements(context).grep(Skymap::Renderer::ScaleBar).first

      expect(bar.to.x - bar.from.x).to be_within(0.05).of(39.82)
    end

    it "puts the bar and its label in the lower left of the map" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      context = context_at(
        latitude: 48.8575,
        canvas: canvas,
        view: view_towards(altitude: 45, azimuth: 180, field_of_view: 20)
      )
      layer = described_class.new

      bar, caption = layer.elements(context)
      points = [bar.from, bar.to, caption.position]

      expect(points.map { |point| distance_from_center(point) }.max)
        .to be < 198.5 - caption.size
      expect(bar.from.x).to be < 200
      expect(bar.to.x).to be < 200
      expect(bar.from.y).to be > 200
      expect(caption.position.y).to be < bar.from.y - bar.tick
      expect(caption.position.x).to eq((bar.from.x + bar.to.x) / 2)
    end

    it "stays inside the sky for every field of view" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      layer = described_class.new

      distances = [180, 60, 10, 1, 0.1, 0.01].flat_map do |field_of_view|
        context = context_at(
          latitude: 48.8575,
          canvas: canvas,
          view: view_towards(
            altitude: 45, azimuth: 180, field_of_view: field_of_view
          )
        )
        bar, caption = layer.elements(context)
        [bar.from, bar.to, caption.position].map do |point|
          distance_from_center(point)
        end
      end

      expect(distances.max).to be < 198.5
    end

    it "draws a caption of the scale kind" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 45, azimuth: 180, field_of_view: 20)
      )
      layer = described_class.new

      caption = layer.elements(context).grep(Skymap::Renderer::Caption).first

      expect(caption.kind).to eq(:scale)
    end

    it "scales its line and text with the canvas" do
      layer = described_class.new
      view = view_towards(altitude: 45, azimuth: 180, field_of_view: 20)
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

      small_bar, small_caption = layer.elements(small)
      large_bar, large_caption = layer.elements(large)

      expect(large_bar.width).to eq(small_bar.width * 2)
      expect(large_caption.size).to eq(small_caption.size * 2)
    end
  end
end
