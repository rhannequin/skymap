# frozen_string_literal: true

RSpec.describe Skymap::Cone do
  it "has a center and a radius" do
    center = equatorial(right_ascension: 12.5, declination: 12.4)
    radius = Astronoby::Angle.from_degrees(5)

    cone = described_class.new(center: center, radius: radius)

    expect(cone.center).to be(center)
    expect(cone.radius).to be(radius)
  end

  it "does not take a center that is not at J2000" do
    center = Astronoby::Coordinates::Equatorial.new(
      right_ascension: Astronoby::Angle.from_hours(12.5),
      declination: Astronoby::Angle.from_degrees(12.4),
      epoch: Astronoby::JulianDate::J2000 + 1
    )

    expect {
      described_class.new(
        center: center,
        radius: Astronoby::Angle.from_degrees(5)
      )
    }.to raise_error(ArgumentError, /center must be/)
  end

  it "does not take a radius of zero" do
    center = equatorial(right_ascension: 12.5, declination: 12.4)

    expect {
      described_class.new(center: center, radius: Astronoby::Angle.zero)
    }.to raise_error(ArgumentError, /radius must be/)
  end

  it "does not take a radius that is not an angle" do
    center = equatorial(right_ascension: 12.5, declination: 12.4)

    expect {
      described_class.new(center: center, radius: 5)
    }.to raise_error(ArgumentError, /radius must be/)
  end
end
