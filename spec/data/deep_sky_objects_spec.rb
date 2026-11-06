# frozen_string_literal: true

require "csv"

RSpec.describe "data/deep_sky_objects.csv" do
  def rows
    CSV.read(Skymap::Catalog::DeepSkyObjects::PATH, headers: true)
  end

  it "has a column for each field of a deep-sky object" do
    headers = rows.headers

    expect(headers).to eq(
      %w[
        designation
        name
        type
        right_ascension
        declination
        magnitude
        magnitude_band
        major_axis
        minor_axis
        position_angle
      ]
    )
  end

  it "has no duplicate designation" do
    designations = rows.map { |row| row["designation"] }

    expect(designations.tally.select { |_, count| count > 1 }).to be_empty
  end

  it "numbers the Messier objects from 1 to 110, except 102" do
    messier = rows.map { |row| row["designation"][/\AM(\d+)\z/, 1] }.compact

    expect(messier.map(&:to_i)).to eq((1..110).to_a - [102])
  end

  it "lists the Messier objects, then the NGC and IC objects" do
    catalogs = rows.map { |row| row["designation"][/\A[A-Z]+/] }

    expect(catalogs.chunk_while { |a, b| a == b }.map(&:first))
      .to eq(%w[M NGC IC])
  end

  it "names the NGC and IC objects without zero padding" do
    designations = rows.map { |row| row["designation"] }
      .reject { |designation| designation.start_with?("M") }

    expect(designations).to all(match(/\A(NGC|IC) [1-9]\d*[A-Z]*\z/))
  end

  it "gives every row a valid deep-sky object" do
    objects = Skymap::Catalog::DeepSkyObjects.new.to_a

    expect(objects.size).to eq(rows.size)
  end

  it "counts the objects of each type" do
    counts = rows.map { |row| row["type"] }.tally

    expect(counts).to eq(
      "galaxy" => 1015,
      "open_cluster" => 359,
      "globular_cluster" => 147,
      "nebula" => 100,
      "planetary_nebula" => 91,
      "supernova_remnant" => 6,
      "asterism" => 13,
      "double_star" => 8,
      "other" => 2
    )
  end

  it "gives a magnitude and its band to every object" do
    missing = rows.select do |row|
      row["magnitude"].nil? || row["magnitude_band"].nil?
    end

    expect(missing).to be_empty
    expect(rows.map { |row| row["magnitude_band"] }.uniq.sort).to eq(%w[B V])
  end

  it "keeps the NGC and IC objects of magnitude 12 or brighter" do
    faint = rows.select do |row|
      row["designation"] !~ /\AM\d/ && row["magnitude"].to_f > 12
    end

    expect(faint).to be_empty
  end

  it "gives a major axis to 1727 objects and a minor axis to 1221" do
    expect(rows.count { |row| row["major_axis"] }).to eq(1727)
    expect(rows.count { |row| row["minor_axis"] }).to eq(1221)
  end

  it "gives a position angle to 1113 objects" do
    count = rows.count { |row| row["position_angle"] }

    expect(count).to eq(1113)
  end

  it "gives the data of the Andromeda Galaxy" do
    m31 = rows.find { |row| row["designation"] == "M31" }

    expect(m31.to_h).to eq(
      "designation" => "M31",
      "name" => "Andromeda Galaxy",
      "type" => "galaxy",
      "right_ascension" => "0.712319",
      "declination" => "41.269056",
      "magnitude" => "3.44",
      "magnitude_band" => "V",
      "major_axis" => "177.83",
      "minor_axis" => "69.66",
      "position_angle" => "35.0"
    )
  end

  it "gives the blue magnitude of the North America Nebula" do
    ngc7000 = rows.find { |row| row["designation"] == "NGC 7000" }

    expect(ngc7000.to_h).to include(
      "name" => "North America Nebula",
      "type" => "nebula",
      "magnitude" => "4.0",
      "magnitude_band" => "B"
    )
  end
end
