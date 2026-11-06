# frozen_string_literal: true

RSpec.describe Skymap::Catalog::DeepSkyObjects do
  def find(designation)
    described_class.new.find { |object| object.designation == designation }
  end

  it "loads every Messier object" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(109)
  end

  it "gives an enumerator without a block" do
    catalog = described_class.new

    first = catalog.each.next

    expect(first.designation).to eq("M1")
  end

  it "reads the Andromeda Galaxy" do
    m31 = find("M31")
    coordinates = m31.equatorial_coordinates

    expect(m31.name).to eq("Andromeda Galaxy")
    expect(m31.type).to eq(:galaxy)
    expect(coordinates.right_ascension.hours.round(6)).to eq(0.712319)
    expect(coordinates.declination.degrees.round(6)).to eq(41.269056)
    expect(coordinates.epoch).to eq(Astronoby::JulianDate::J2000)
    expect(m31.magnitude).to eq(3.44)
    expect(m31.major_axis.degrees * 60).to be_within(1e-9).of(177.83)
    expect(m31.minor_axis.degrees * 60).to be_within(1e-9).of(69.66)
    expect(m31.position_angle.degrees).to eq(35)
  end

  it "reads a globular cluster, which has no minor axis" do
    m13 = find("M13")

    expect(m13.name).to eq("Hercules Globular Cluster")
    expect(m13.type).to eq(:globular_cluster)
    expect(m13.major_axis.degrees * 60).to be_within(1e-9).of(16.5)
    expect(m13.minor_axis).to be_nil
    expect(m13.position_angle).to be_nil
  end

  it "reads a planetary nebula" do
    expect(find("M57").type).to eq(:planetary_nebula)
  end

  it "reads the Orion Nebula as a nebula" do
    expect(find("M42").type).to eq(:nebula)
  end

  it "reads the Crab Nebula as a supernova remnant" do
    expect(find("M1").type).to eq(:supernova_remnant)
  end

  it "reads M40, a double star without a size, from the addendum" do
    m40 = find("M40")

    expect(m40.type).to eq(:double_star)
    expect(m40.name).to be_nil
    expect(m40.magnitude).to eq(8.0)
    expect(m40.axes).to be_nil
  end

  it "reads the Pleiades, from the addendum, as an open cluster" do
    m45 = find("M45")

    expect(m45.type).to eq(:open_cluster)
    expect(m45.name).to eq("Pleiades")
    expect(m45.major_axis.degrees).to be_within(1e-9).of(2.5)
  end

  it "leaves out M102" do
    expect(find("M102")).to be_nil
  end
end
