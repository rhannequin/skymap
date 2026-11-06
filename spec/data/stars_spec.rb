# frozen_string_literal: true

require "csv"

RSpec.describe "data/stars.csv" do
  def rows
    CSV.read(File.expand_path("../../data/stars.csv", __dir__), headers: true)
  end

  def row(hr)
    rows.find { |row| row["hr"] == hr.to_s }
  end

  it "has a column for each field of a star" do
    headers = rows.headers

    expect(headers).to eq(
      %w[
        hr
        right_ascension
        declination
        magnitude
        proper_motion_ra
        proper_motion_dec
        parallax
        radial_velocity
      ]
    )
  end

  it "gives a proper motion in mas/yr to every star" do
    missing = rows.select do |row|
      row["proper_motion_ra"].nil? || row["proper_motion_dec"].nil?
    end

    expect(missing).to be_empty
  end

  it "gives a parallax in mas to 3100 stars" do
    count = rows.count { |row| row["parallax"] }

    expect(count).to eq(3100)
  end

  it "gives a radial velocity in km/s to 9090 stars" do
    count = rows.count { |row| row["radial_velocity"] }

    expect(count).to eq(9090)
  end

  it "keeps parallaxes above zero" do
    parallaxes = rows.filter_map { |row| row["parallax"]&.to_i }

    expect(parallaxes).to all(be > 0)
  end

  it "gives the astrometry of Arcturus" do
    arcturus = row(5340)

    expect(arcturus["proper_motion_ra"]).to eq("-1093")
    expect(arcturus["proper_motion_dec"]).to eq("-1998")
    expect(arcturus["parallax"]).to eq("90")
    expect(arcturus["radial_velocity"]).to eq("-5")
  end

  it "gives the astrometry of Sirius" do
    sirius = row(2491)

    expect(sirius["proper_motion_ra"]).to eq("-553")
    expect(sirius["proper_motion_dec"]).to eq("-1205")
    expect(sirius["parallax"]).to eq("375")
    expect(sirius["radial_velocity"]).to eq("-8")
  end

  it "gives the astrometry of 61 Cygni A" do
    star = row(8085)

    expect(star["proper_motion_ra"]).to eq("4136")
    expect(star["proper_motion_dec"]).to eq("3203")
    expect(star["parallax"]).to eq("292")
    expect(star["radial_velocity"]).to eq("-64")
  end

  it "leaves the parallax and the radial velocity blank when unknown" do
    star = row(1630)

    expect(star["parallax"]).to be_nil
    expect(star["radial_velocity"]).to be_nil
  end
end

RSpec.describe "data/stars.bin" do
  def records
    Skymap::Catalog::StarRecords.new(
      File.binread(Skymap::Catalog::Stars::PATH)
    )
  end

  it "has the 9,096 stars of the Bright Star Catalogue and 121,460 more" do
    catalog = records

    numbered = catalog.each_with_hr.count
    others = catalog.count - numbered

    expect(numbered).to eq(9096)
    expect(others).to eq(121_460)
  end

  it "has no star fainter than magnitude 9" do
    catalog = records

    faintest = catalog.each.map(&:magnitude).max

    expect(faintest).to eq(9.0)
  end

  it "gives a proper motion to all but 6 stars" do
    catalog = records

    missing = catalog.each.count { |star| star.proper_motion_ra.nil? }

    expect(missing).to eq(6)
  end

  it "gives a parallax to 120,940 stars" do
    catalog = records

    count = catalog.each.count(&:parallax)

    expect(count).to eq(120_940)
  end

  it "gives a radial velocity to 104,692 stars" do
    catalog = records

    count = catalog.each.count(&:radial_velocity)

    expect(count).to eq(104_692)
  end

  it "gives a proper motion, a parallax and a radial velocity to most others" do
    catalog = records

    count = catalog.each.count do |star|
      star.hr.nil? && star.proper_motion_ra && star.parallax &&
        star.radial_velocity
    end

    expect(count).to be > 95_000
  end
end
