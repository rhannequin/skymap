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
    numbers = rows.map { |row| row["designation"][/\AM(\d+)\z/, 1].to_i }

    expect(numbers).to eq((1..110).to_a - [102])
  end

  it "gives every row a valid deep-sky object" do
    objects = Skymap::Catalog::DeepSkyObjects.new.to_a

    expect(objects.size).to eq(rows.size)
  end

  it "counts the objects of each type" do
    counts = rows.map { |row| row["type"] }.tally

    expect(counts).to eq(
      "galaxy" => 39,
      "open_cluster" => 26,
      "globular_cluster" => 29,
      "nebula" => 7,
      "planetary_nebula" => 4,
      "supernova_remnant" => 1,
      "asterism" => 1,
      "double_star" => 1,
      "other" => 1
    )
  end

  it "gives a magnitude to every object" do
    missing = rows.select { |row| row["magnitude"].nil? }

    expect(missing).to be_empty
  end

  it "gives a major axis to 107 objects and a minor axis to 47" do
    expect(rows.count { |row| row["major_axis"] }).to eq(107)
    expect(rows.count { |row| row["minor_axis"] }).to eq(47)
  end

  it "gives a position angle to 41 objects" do
    count = rows.count { |row| row["position_angle"] }

    expect(count).to eq(41)
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
      "major_axis" => "177.83",
      "minor_axis" => "69.66",
      "position_angle" => "35.0"
    )
  end
end
