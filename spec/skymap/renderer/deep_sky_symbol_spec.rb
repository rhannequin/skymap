# frozen_string_literal: true

RSpec.describe Skymap::Renderer::DeepSkySymbol do
  def symbol(kind: :galaxy, semi_major: 40.0, semi_minor: 10.0, rotation: 0.0)
    described_class.new(
      center: Skymap::Point.new(x: 100, y: 200),
      kind: kind,
      semi_major: semi_major,
      semi_minor: semi_minor,
      rotation: rotation,
      width: 1
    )
  end

  describe "#hollow?" do
    it "is true for the symbols that are only an outline" do
      hollow = %i[
        galaxy open_cluster asterism supernova_remnant planetary_nebula nebula
      ].map { |kind| symbol(kind: kind).hollow? }

      expect(hollow).to all(be(true))
    end

    it "is false for the symbols with marks inside" do
      marked = %i[globular_cluster double_star other]
        .map { |kind| symbol(kind: kind).hollow? }

      expect(marked).to all(be(false))
    end
  end

  describe "#outline" do
    it "follows the ellipse of the symbol" do
      outline = symbol.outline

      distances = outline.map do |point|
        ((point.x - 100) / 40.0)**2 + ((point.y - 200) / 10.0)**2
      end

      expect(distances).to all(be_within(1e-9).of(1))
    end

    it "turns with the rotation, in degrees as the SVG does" do
      outline = symbol(rotation: 90.0).outline

      reach = outline.map { |point| (point.y - 200).abs }.max

      expect(reach).to be_within(1e-9).of(40)
    end

    it "is the four corners of a nebula" do
      outline = symbol(kind: :nebula, semi_major: 30.0, semi_minor: 20.0)
        .outline

      expect(outline.map { |point| [point.x, point.y] }).to eq(
        [[70.0, 180.0], [130.0, 180.0], [130.0, 220.0], [70.0, 220.0]]
      )
    end

    it "has more points for a larger symbol" do
      small = symbol(semi_major: 5.0, semi_minor: 5.0).outline
      large = symbol(semi_major: 300.0, semi_minor: 100.0).outline

      expect(large.size).to be > small.size
    end

    it "stays close to the ellipse, within half a pixel" do
      outline = symbol(semi_major: 200.0, semi_minor: 200.0).outline
      midpoints = outline.zip(outline.rotate).map do |from, to|
        Math.hypot((from.x + to.x) / 2 - 100, (from.y + to.y) / 2 - 200)
      end

      expect(midpoints.min).to be >= 199.5
    end

    it "stays close to the ellipse of a symbol far larger than the map" do
      outline = symbol(semi_major: 20_000.0, semi_minor: 20_000.0).outline
      midpoints = outline.zip(outline.rotate).map do |from, to|
        Math.hypot((from.x + to.x) / 2 - 100, (from.y + to.y) / 2 - 200)
      end

      expect(midpoints.min).to be >= 19_999.5
    end
  end
end
