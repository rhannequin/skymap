# frozen_string_literal: true

RSpec.describe Skymap::Theme do
  describe ".dark" do
    it "is a light-on-black sky" do
      theme = described_class.dark

      expect(theme.sky).to eq("#000000")
      expect(theme.star).to eq("#ffffff")
    end
  end

  describe ".light" do
    it "is a dark-on-white sky" do
      theme = described_class.light

      expect(theme.sky).to eq("#ffffff")
      expect(theme.star).to eq("#111111")
    end
  end

  describe ".night" do
    it "keeps every color in the reds" do
      theme = described_class.night
      colors = theme.to_h.except(:moon_shadow_opacity, :font).values

      colors.each do |color|
        red, green, blue = color.delete("#").scan(/../).map { |c| c.to_i(16) }

        expect(red).to be >= green
        expect(red).to be >= blue
      end
    end
  end

  describe "#with" do
    it "changes the given colors and keeps the others" do
      theme = described_class.dark.with(star: "#ffeedd")

      expect(theme.star).to eq("#ffeedd")
      expect(theme.sky).to eq(described_class.dark.sky)
    end
  end

  describe ".new" do
    it "rejects a color that is not a string" do
      expect { described_class.dark.with(star: 0xffffff) }
        .to raise_error(ArgumentError, /star must be a string/)
    end

    it "rejects an empty color" do
      expect { described_class.dark.with(star: "") }
        .to raise_error(ArgumentError, /star must not be blank/)
    end

    it "rejects a color made of spaces" do
      expect { described_class.dark.with(sky: "  ") }
        .to raise_error(ArgumentError, /sky must not be blank/)
    end

    it "rejects a shadow opacity above 1" do
      expect { described_class.dark.with(moon_shadow_opacity: 1.5) }
        .to raise_error(ArgumentError, /moon_shadow_opacity/)
    end

    it "rejects a negative shadow opacity" do
      expect { described_class.dark.with(moon_shadow_opacity: -0.1) }
        .to raise_error(ArgumentError, /moon_shadow_opacity/)
    end

    it "rejects a shadow opacity that is not a number" do
      expect { described_class.dark.with(moon_shadow_opacity: "0.5") }
        .to raise_error(ArgumentError, /moon_shadow_opacity/)
    end

    it "rejects a shadow opacity that is not a real number" do
      opacity = Complex(0.5, 0.25)

      expect { described_class.dark.with(moon_shadow_opacity: opacity) }
        .to raise_error(ArgumentError, /moon_shadow_opacity/)
    end

    it "accepts a shadow opacity that is a rational number" do
      theme = described_class.dark.with(moon_shadow_opacity: Rational(1, 2))

      expect(theme.moon_shadow_opacity).to eq(0.5)
    end

    it "requires every slot" do
      expect { described_class.new(sky: "#000000") }
        .to raise_error(ArgumentError, /missing keywords/)
    end
  end
end
