# frozen_string_literal: true

RSpec.describe Skymap::Catalog::Stars do
  it "loads every star of the Bright Star Catalogue" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(9096)
  end

  it "reads the identifier, J2000 coordinates and magnitude of each star" do
    catalog = described_class.new

    sirius = catalog.find { |star| star.hr == 2491 }
    coordinates = sirius.equatorial_coordinates

    expect(coordinates.right_ascension.hours.round(6)).to eq(6.752472)
    expect(coordinates.declination.degrees.round(6)).to eq(-16.716111)
    expect(coordinates.epoch).to eq(Astronoby::JulianDate::J2000)
    expect(sirius.magnitude).to eq(-1.46)
  end
end
