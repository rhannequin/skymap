# frozen_string_literal: true

RSpec.describe Skymap::Theme do
  describe ".dark" do
    it "is a light-on-black sky" do
      theme = described_class.dark

      expect(theme.sky).to eq("#000000")
      expect(theme.star).to eq("#ffffff")
    end

    it "has no background" do
      expect(described_class.dark.background).to eq("none")
    end
  end

  describe ".light" do
    it "is a dark-on-white sky" do
      theme = described_class.light

      expect(theme.sky).to eq("#ffffff")
      expect(theme.star).to eq("#111111")
    end

    it "has a white background, like paper" do
      expect(described_class.light.background).to eq("#ffffff")
    end
  end

  describe ".night" do
    it "keeps every color in the reds" do
      theme = described_class.night
      slots = theme.members - [:moon_shadow_opacity, :font]

      slots.map { |slot| theme.public_send(slot) }.each do |color|
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

    it "requires every slot that is not optional" do
      expect { described_class.new(sky: "#000000") }
        .to raise_error(ArgumentError, /missing keywords/)
    end

    it "still requires a slot that was already required" do
      slots = theme_from_0_4_0.to_h.except(:star)

      expect { described_class.new(**slots) }
        .to raise_error(ArgumentError, /missing keyword: :star/)
    end

    it "does not accept nil for a slot that is not optional" do
      expect { described_class.dark.with(star: nil) }
        .to raise_error(ArgumentError, /star must be a string/)
    end

    it "builds a theme written for 0.4.0" do
      theme = theme_from_0_4_0

      expect(theme.star).to eq("#ffffff")
      expect(theme.grid).to eq("#2b3f5e")
    end
  end

  describe ".new with positional arguments" do
    it "takes the 17 colors in the order of 0.4.0" do
      slots = %i[
        background sky horizon star constellation_line boundary ecliptic
        planet sun moon moon_shadow moon_shadow_opacity constellation_name
        star_name planet_name label font
      ]
      values = slots.each_with_index.map { |slot, index|
        (slot == :moon_shadow_opacity) ? 0.5 : "color-#{index}"
      }

      theme = described_class.new(*values)

      expect(slots.map { |slot| theme.public_send(slot) }).to eq(values)
      expect(theme.grid).to eq(theme.boundary)
    end
  end

  describe "an optional color" do
    it "is the color of its fallback when it is not set" do
      theme = theme_from_0_4_0

      expect(theme.grid).to eq(theme.boundary)
    end

    it "is its own color when it is set" do
      theme = theme_from_0_4_0.with(grid: "#123456")

      expect(theme.grid).to eq("#123456")
    end

    it "follows its fallback when the fallback changes" do
      theme = theme_from_0_4_0.with(boundary: "#abcdef")

      expect(theme.grid).to eq("#abcdef")
    end

    it "does not follow its fallback once it is set" do
      theme = theme_from_0_4_0.with(grid: "#123456", boundary: "#abcdef")

      expect(theme.grid).to eq("#123456")
    end

    it "goes back to its fallback when it is set to nil" do
      theme = described_class.dark.with(grid: nil)

      expect(theme.grid).to eq(theme.boundary)
    end

    it "keeps following a fallback changed on a built-in theme" do
      theme = described_class.dark.with(grid: nil, boundary: "#ffffff")

      expect(theme.grid).to eq("#ffffff")
    end

    it "rejects a color that is not a string" do
      expect { described_class.dark.with(grid: 0xffffff) }
        .to raise_error(ArgumentError, /grid must be a string/)
    end

    it "rejects an empty color" do
      expect { described_class.dark.with(grid: "") }
        .to raise_error(ArgumentError, /grid must not be blank/)
    end

    it "rejects a color made of spaces" do
      expect { described_class.dark.with(grid: "  ") }
        .to raise_error(ArgumentError, /grid must not be blank/)
    end

    it "is accepted by the built-in themes" do
      grids = %i[dark light night].map { |name|
        described_class.public_send(name).grid
      }

      expect(grids).to eq(["#22324a", "#d5ddea", "#3a0e0e"])
    end
  end

  describe ".check_fallbacks" do
    it "accepts a fallback that is a required slot" do
      required = described_class.members - [:grid]

      expect { described_class.check_fallbacks({grid: :boundary}, required) }
        .not_to raise_error
    end

    it "rejects a fallback that is not a slot" do
      required = described_class.members - [:grid]

      expect { described_class.check_fallbacks({grid: :bondary}, required) }
        .to raise_error(ArgumentError, /grid must fall back to a required slot/)
    end

    it "rejects a fallback that is an optional slot" do
      required = described_class.members - [:grid, :scale]
      table = {grid: :scale, scale: :grid}

      expect { described_class.check_fallbacks(table, required) }
        .to raise_error(ArgumentError, /grid must fall back to a required slot/)
    end
  end

  {scale: :star_name, field_circle: :planet}.each do |slot, fallback|
    describe "the #{slot} color" do
      it "is the #{fallback} color when it is not set" do
        theme = theme_from_0_4_0

        expect(theme.public_send(slot)).to eq(theme.public_send(fallback))
      end

      it "is its own color when it is set" do
        theme = theme_from_0_4_0.with(slot => "#123456")

        expect(theme.public_send(slot)).to eq("#123456")
      end

      it "follows the #{fallback} color when it is not set" do
        theme = described_class.dark.with(fallback => "#abcdef")

        expect(theme.public_send(slot)).to eq("#abcdef")
      end

      it "is left to its fallback by the built-in themes" do
        themes = [described_class.dark, described_class.light,
          described_class.night]

        expect(themes.map { |theme| theme.to_h[slot] }).to eq([nil, nil, nil])
      end

      it "rejects a blank color" do
        expect { described_class.dark.with(slot => " ") }
          .to raise_error(ArgumentError, /#{slot} must not be blank/)
      end
    end
  end

  describe "#to_h" do
    it "gives an optional color as it was set, nil when it was not" do
      unset = theme_from_0_4_0.to_h
      set = theme_from_0_4_0.with(grid: "#123456").to_h

      expect(unset[:grid]).to be_nil
      expect(set[:grid]).to eq("#123456")
    end

    it "builds the same theme back" do
      theme = theme_from_0_4_0

      expect(described_class.new(**theme.to_h)).to eq(theme)
    end
  end

  describe "the slots that were set" do
    it "are what to_h, inspect, == and pattern matching work on" do
      theme = theme_from_0_4_0
      explicit = theme.with(grid: theme.boundary)

      matched = case theme
      in {grid: nil, boundary:} then boundary
      end

      expect(theme.grid).to eq(theme.boundary)
      expect(theme.to_h).to include(grid: nil)
      expect(theme.inspect).to include("grid=nil")
      expect(matched).to eq(theme.boundary)
      expect(explicit).not_to eq(theme)
    end
  end

  describe "#==" do
    it "tells apart a color that is set from one that falls back" do
      fallback = theme_from_0_4_0
      explicit = theme_from_0_4_0.with(grid: fallback.boundary)

      expect(explicit).not_to eq(fallback)
      expect(theme_from_0_4_0).to eq(fallback)
    end
  end

  describe "#inspect" do
    it "shows an optional color that is not set as nil" do
      expect(theme_from_0_4_0.inspect).to include("grid=nil")
    end
  end
end
