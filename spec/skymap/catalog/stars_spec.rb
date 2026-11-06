# frozen_string_literal: true

RSpec.describe Skymap::Catalog::Stars do
  it "loads every star of the Bright Star Catalogue" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(9096)
  end

  it "gives an enumerator without a block" do
    catalog = described_class.new

    first = catalog.each.next

    expect(first.hr).to eq(1)
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

  it "reads the proper motion, parallax and radial velocity of a star" do
    catalog = described_class.new

    arcturus = catalog.find { |star| star.hr == 5340 }

    expect(arcturus.proper_motion_ra).to eq(
      Astronoby::AngularVelocity.from_milliarcseconds_per_year(-1093)
    )
    expect(arcturus.proper_motion_dec).to eq(
      Astronoby::AngularVelocity.from_milliarcseconds_per_year(-1998)
    )
    expect(arcturus.parallax).to eq(
      Astronoby::Angle.from_degree_arcseconds(0.09)
    )
    expect(arcturus.radial_velocity.kmps).to eq(-5)
  end

  it "leaves out the parallax and the radial velocity a star has none of" do
    catalog = described_class.new

    star = catalog.find { |star| star.hr == 1630 }

    expect(star.proper_motion_ra).not_to be_nil
    expect(star.parallax).to be_nil
    expect(star.radial_velocity).to be_nil
  end
end
