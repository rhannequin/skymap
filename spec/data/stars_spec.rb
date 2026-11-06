# frozen_string_literal: true

require "csv"

RSpec.describe "data/stars.csv" do
  def rows
    CSV.read(Skymap::Catalog::Stars::PATH, headers: true)
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
