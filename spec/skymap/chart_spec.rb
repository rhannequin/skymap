# frozen_string_literal: true

RSpec.describe Skymap::Chart do
  describe "#render" do
    it "renders the sky on the given canvas" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 1000, padding: 1.5)
      )

      svg = chart.render
      root = REXML::Document.new(svg).root

      expect(root["viewBox"]).to eq("0 0 1000 1000")
    end

    it "draws an empty sky without layers" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      svg = chart.render
      elements = REXML::Document.new(svg).root.elements.map(&:name)

      expect(elements).to eq(["circle"])
    end

    it "draws the layers in the given order" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)
      ]

      svg = chart.render(
        Skymap::Layers::CardinalDirections.new,
        Skymap::Layers::Stars.new(stars: stars),
        Skymap::Layers::ConstellationLines.new(
          lines: [constellation_line(from: [1], to: [2])],
          stars: stars
        )
      )
      _sky, *elements = REXML::Document.new(svg).root.elements.map(&:name)

      expect(elements).to eq(%w[text text text text circle circle line])
    end

    it "gives every layer the same context" do
      chart = described_class.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = recording_layer
      second = recording_layer

      chart.render(first, second)

      expect(first.contexts.size).to eq(1)
      expect(second.contexts).to eq(first.contexts)
    end
  end

  def recording_layer
    Class.new do
      def contexts = @contexts ||= []

      def elements(context)
        contexts << context
        []
      end
    end.new
  end
end
