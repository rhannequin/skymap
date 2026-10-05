# frozen_string_literal: true

RSpec.describe Skymap::Layers::CardinalDirections do
  describe "#elements" do
    it "labels the cardinal directions in the padding" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )
      layer = described_class.new

      labels = layer.elements(context).map do |label|
        [label.text, label.position.x.round(2), label.position.y.round(2)]
      end

      expect(labels).to contain_exactly(
        ["N", 200.0, 10.0],
        ["E", 10.0, 200.0],
        ["S", 200.0, 390.0],
        ["W", 390.0, 200.0]
      )
    end

    it "sizes the cardinal directions to fit in the padding" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )
      layer = described_class.new

      sizes = layer.elements(context).map(&:size)

      expect(sizes).to all(eq(12.0))
    end
  end
end
