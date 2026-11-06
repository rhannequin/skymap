# frozen_string_literal: true

RSpec.describe Skymap::MagnitudeLimit do
  describe ".check" do
    it "accepts an integer, a float and a negative limit" do
      expect { described_class.check(5) }.not_to raise_error
      expect { described_class.check(6.5) }.not_to raise_error
      expect { described_class.check(-1) }.not_to raise_error
    end

    it "rejects nil by default" do
      expect { described_class.check(nil) }.to raise_error(
        ArgumentError,
        "magnitude_limit must be a finite Numeric"
      )
    end

    it "accepts nil when asked to" do
      expect { described_class.check(nil, allow_nil: true) }
        .not_to raise_error
    end

    it "rejects a value that is not a number" do
      expect { described_class.check("5") }
        .to raise_error(ArgumentError, /magnitude_limit/)
    end

    it "rejects a value that is not finite" do
      expect { described_class.check(Float::NAN) }
        .to raise_error(ArgumentError, /magnitude_limit/)
      expect { described_class.check(Float::INFINITY) }
        .to raise_error(ArgumentError, /magnitude_limit/)
    end

    it "rejects a complex number" do
      expect { described_class.check(Complex(1, 1)) }
        .to raise_error(ArgumentError, /magnitude_limit/)
    end

    it "names the limit that is wrong" do
      expect { described_class.check("5", name: :stars_magnitude_limit) }
        .to raise_error(ArgumentError, /\Astars_magnitude_limit must be/)
    end

    it "says that nil is accepted when it is" do
      expect { described_class.check("5", allow_nil: true) }
        .to raise_error(ArgumentError, /or nil/)
    end
  end
end
