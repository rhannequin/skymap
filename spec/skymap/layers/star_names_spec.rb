# frozen_string_literal: true

RSpec.describe Skymap::Layers::StarNames do
  describe "#elements" do
    it "names a star under it when it is in the upper half of the map" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      polaris = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 424)
      layer = described_class.new(stars: [polaris])
      radius = Skymap::StarSize.for(
        canvas: context.canvas,
        magnitude_limit: 5
      ).radius(2)

      caption, = layer.elements(context)

      expect(caption.text).to eq("Polaris")
      expect(caption.kind).to eq(:star)
      expect(caption.size).to be_within(0.001).of(5.6)
      expect(caption.position.x).to eq(context.position(polaris).x)
      expect(caption.position.y).to be_within(0.001).of(
        context.position(polaris).y + radius + caption.size
      )
    end

    it "names a star over it when it is in the lower half of the map" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      sirius = star(right_ascension: 1, declination: 20, magnitude: 1, hr: 2491)
      layer = described_class.new(stars: [sirius])
      radius = Skymap::StarSize.for(
        canvas: context.canvas,
        magnitude_limit: 5
      ).radius(1)

      caption, = layer.elements(context)

      expect(caption.position.y).to be_within(0.001).of(
        context.position(sirius).y - radius - caption.size
      )
    end

    it "leaves out the stars below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      set = star(right_ascension: 6, declination: -60, magnitude: 1, hr: 2491)
      layer = described_class.new(stars: [set])

      captions = layer.elements(context)

      expect(captions).to be_empty
    end

    it "leaves out the stars without a name" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      anonymous = star(right_ascension: 0, declination: 89, magnitude: 1, hr: 1)
      layer = described_class.new(stars: [anonymous])

      captions = layer.elements(context)

      expect(captions).to be_empty
    end

    it "leaves out stars fainter than magnitude 2 by default" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      bright = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 424)
      faint = star(right_ascension: 1, declination: 20, magnitude: 2.1,
        hr: 5054)
      layer = described_class.new(stars: [bright, faint])

      captions = layer.elements(context)

      expect(captions.map(&:text)).to eq(["Polaris"])
    end

    it "leaves out stars fainter than the given magnitude limit" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      bright = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 424)
      faint = star(right_ascension: 1, declination: 20, magnitude: 2.1,
        hr: 5054)
      layer = described_class.new(
        stars: [bright, faint],
        magnitude_limit: 3
      )

      captions = layer.elements(context)

      expect(captions.map(&:text)).to eq(%w[Polaris Mizar])
    end

    it "places names for the size of the stars drawn down to the given limit" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      sirius = star(right_ascension: 1, declination: 20, magnitude: 1, hr: 2491)
      layer = described_class.new(stars: [sirius], stars_magnitude_limit: 7)
      radius = Skymap::StarSize.for(
        canvas: context.canvas,
        magnitude_limit: 7
      ).radius(1)

      caption, = layer.elements(context)

      expect(caption.position.y).to be_within(0.001).of(
        context.position(sirius).y - radius - caption.size
      )
    end

    it "names the stars with the given names" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      polaris = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 424)
      layer = described_class.new(
        stars: [polaris],
        names: {424 => "Étoile polaire"}
      )

      caption, = layer.elements(context)

      expect(caption.text).to eq("Étoile polaire")
    end

    it "draws names with a size that follows the canvas" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      polaris = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 424)
      layer = described_class.new(stars: [polaris])

      small_caption, = layer.elements(small)
      large_caption, = layer.elements(large)

      expect(small_caption.size).to be_within(0.001).of(5.6)
      expect(large_caption.size).to be_within(0.001).of(11.2)
    end
  end
end
