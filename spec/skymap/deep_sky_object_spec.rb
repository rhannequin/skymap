# frozen_string_literal: true

RSpec.describe Skymap::DeepSkyObject do
  def object(**attributes)
    described_class.new(
      designation: "M31",
      type: :galaxy,
      equatorial_coordinates: equatorial(
        right_ascension: 0.712319,
        declination: 41.269056
      ),
      **attributes
    )
  end

  def arcminutes(value)
    Astronoby::Angle.from_degrees(value / 60.0)
  end

  describe "TYPES" do
    it "lists the types of deep-sky objects" do
      types = described_class::TYPES

      expect(types).to eq(
        %i[
          galaxy
          open_cluster
          globular_cluster
          planetary_nebula
          nebula
          supernova_remnant
          asterism
          double_star
          other
        ]
      )
      expect(types).to be_frozen
    end

    it "does not leak into Skymap" do
      expect(Skymap.const_defined?(:TYPES, false)).to be(false)
    end
  end

  describe ".new" do
    it "has no name, magnitude, size or position angle by default" do
      object = object()

      expect(object.name).to be_nil
      expect(object.magnitude).to be_nil
      expect(object.major_axis).to be_nil
      expect(object.minor_axis).to be_nil
      expect(object.position_angle).to be_nil
    end

    it "takes a name, a magnitude, axes and a position angle" do
      object = object(
        name: "Andromeda Galaxy",
        magnitude: 3.44,
        major_axis: arcminutes(177.83),
        minor_axis: arcminutes(69.66),
        position_angle: Astronoby::Angle.from_degrees(35)
      )

      expect(object.designation).to eq("M31")
      expect(object.name).to eq("Andromeda Galaxy")
      expect(object.type).to eq(:galaxy)
      expect(object.equatorial_coordinates.declination.degrees)
        .to be_within(1e-9).of(41.269056)
      expect(object.magnitude).to eq(3.44)
      expect(object.major_axis).to eq(arcminutes(177.83))
      expect(object.minor_axis).to eq(arcminutes(69.66))
      expect(object.position_angle).to eq(Astronoby::Angle.from_degrees(35))
    end

    it "takes every type" do
      objects = described_class::TYPES.map { |type| object(type: type) }

      expect(objects.map(&:type)).to eq(described_class::TYPES)
    end

    it "takes a major axis as the minor axis of a round object" do
      major = arcminutes(16.5)
      object = object(major_axis: major)

      expect(object.minor_axis).to eq(major)
    end

    it "keeps both axes unknown when the size is unknown" do
      object = object()

      expect(object.major_axis).to be_nil
      expect(object.minor_axis).to be_nil
    end

    it "takes an axis as large as the other" do
      object = object(major_axis: arcminutes(28), minor_axis: arcminutes(28))

      expect(object.minor_axis).to eq(object.major_axis)
    end

    it "takes a position angle without axes" do
      object = object(position_angle: Astronoby::Angle.from_degrees(90))

      expect(object.position_angle).to eq(Astronoby::Angle.from_degrees(90))
    end

    it "rejects a designation that is not a String" do
      expect { object(designation: :m31) }.to raise_error(
        ArgumentError,
        "designation must be a non-blank String"
      )
    end

    it "rejects a blank designation" do
      expect { object(designation: " ") }.to raise_error(
        ArgumentError,
        "designation must be a non-blank String"
      )
    end

    it "rejects a name that is not a String" do
      expect { object(name: 31) }.to raise_error(
        ArgumentError,
        "name must be a non-blank String or nil"
      )
    end

    it "rejects a blank name" do
      expect { object(name: "") }.to raise_error(
        ArgumentError,
        "name must be a non-blank String or nil"
      )
    end

    it "rejects an unknown type" do
      expect { object(type: :star) }.to raise_error(
        ArgumentError,
        "type must be one of #{described_class::TYPES.join(", ")}"
      )
    end

    it "rejects a type given as a String" do
      expect { object(type: "galaxy") }.to raise_error(
        ArgumentError,
        /type must be one of/
      )
    end

    it "rejects coordinates that are not equatorial" do
      horizontal = Astronoby::Coordinates::Horizontal.new(
        altitude: Astronoby::Angle.from_degrees(40),
        azimuth: Astronoby::Angle.from_degrees(180),
        observer: observer_at(latitude: 48.8575)
      )

      expect { object(equatorial_coordinates: horizontal) }.to raise_error(
        ArgumentError,
        "equatorial_coordinates must be Astronoby::Coordinates::Equatorial " \
        "at J2000"
      )
    end

    it "rejects coordinates at another epoch" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
      of_date = Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(0.7),
        declination: Astronoby::Angle.from_degrees(41.2),
        epoch: instant.tt
      )

      expect { object(equatorial_coordinates: of_date) }.to raise_error(
        ArgumentError,
        /at J2000/
      )
    end

    it "rejects a magnitude that is not a Numeric" do
      expect { object(magnitude: "3.44") }.to raise_error(
        ArgumentError,
        "magnitude must be a finite Numeric or nil"
      )
    end

    it "rejects a magnitude that is not finite" do
      expect { object(magnitude: Float::NAN) }.to raise_error(
        ArgumentError,
        "magnitude must be a finite Numeric or nil"
      )
      expect { object(magnitude: Float::INFINITY) }.to raise_error(
        ArgumentError,
        "magnitude must be a finite Numeric or nil"
      )
    end

    it "rejects a major axis that is not an Astronoby::Angle" do
      expect { object(major_axis: 177.83) }.to raise_error(
        ArgumentError,
        "major_axis must be an Astronoby::Angle above 0 or nil"
      )
    end

    it "rejects a major axis that is not above zero" do
      expect { object(major_axis: Astronoby::Angle.zero) }.to raise_error(
        ArgumentError,
        "major_axis must be an Astronoby::Angle above 0 or nil"
      )
      expect { object(major_axis: arcminutes(-1)) }.to raise_error(
        ArgumentError,
        "major_axis must be an Astronoby::Angle above 0 or nil"
      )
    end

    it "rejects a minor axis that is not above zero" do
      expect {
        object(major_axis: arcminutes(10), minor_axis: Astronoby::Angle.zero)
      }.to raise_error(
        ArgumentError,
        "minor_axis must be an Astronoby::Angle above 0 or nil"
      )
    end

    it "rejects a minor axis that is not an Astronoby::Angle" do
      expect {
        object(major_axis: arcminutes(10), minor_axis: 5)
      }.to raise_error(
        ArgumentError,
        "minor_axis must be an Astronoby::Angle above 0 or nil"
      )
    end

    it "rejects a minor axis without a major axis" do
      expect { object(minor_axis: arcminutes(5)) }.to raise_error(
        ArgumentError,
        "minor_axis must come with a major_axis"
      )
    end

    it "rejects a minor axis larger than the major axis" do
      expect {
        object(major_axis: arcminutes(5), minor_axis: arcminutes(10))
      }.to raise_error(
        ArgumentError,
        "minor_axis must not be larger than major_axis"
      )
    end

    it "rejects a position angle that is not an Astronoby::Angle" do
      expect { object(position_angle: 35) }.to raise_error(
        ArgumentError,
        "position_angle must be an Astronoby::Angle or nil"
      )
    end
  end
end
