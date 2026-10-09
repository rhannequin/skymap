# frozen_string_literal: true

RSpec.describe Skymap::Catalog::ConstellationBoundaries do
  it "loads every border between constellations" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(266)
  end

  it "reads the two constellations a border separates" do
    catalog = described_class.new

    boundary = catalog.find { |border| border.constellations == %w[Cru Mus] }

    expect(boundary.points.size).to be > 2
  end

  it "reads the points of a border in J2000 coordinates" do
    catalog = described_class.new

    boundary = catalog.find { |border| border.constellations == %w[Cru Mus] }
    point = boundary.points.first

    expect(point.epoch).to eq(Astronoby::JulianDate::J2000)
    expect(point.right_ascension.hours).to be_between(11, 13)
    expect(point.declination.degrees).to be_between(-65, -55)
  end
end
