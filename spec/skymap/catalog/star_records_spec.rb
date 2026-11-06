# frozen_string_literal: true

RSpec.describe Skymap::Catalog::StarRecords do
  def record(right_ascension: 10.0, declination: 20.0, magnitude: 5.0, **rest)
    described_class::Record.new(
      right_ascension: right_ascension,
      declination: declination,
      magnitude: magnitude,
      proper_motion_ra: rest[:proper_motion_ra],
      proper_motion_dec: rest[:proper_motion_dec],
      parallax: rest[:parallax],
      radial_velocity: rest[:radial_velocity],
      hr: rest[:hr]
    )
  end

  def catalog(*records)
    described_class.new(described_class.encode(records))
  end

  it "reads back the fields of a star" do
    star = record(
      right_ascension: 213.915417,
      declination: 19.1825,
      magnitude: -0.04,
      proper_motion_ra: -1093,
      proper_motion_dec: -1998,
      parallax: 90.0,
      radial_velocity: -5,
      hr: 5340
    )
    records = catalog(star)

    read = records.each.first

    expect(read.right_ascension).to be_within(1e-6).of(213.915417)
    expect(read.declination).to be_within(1e-6).of(19.1825)
    expect(read.magnitude).to eq(-0.04)
    expect(read.proper_motion_ra).to eq(-1093)
    expect(read.proper_motion_dec).to eq(-1998)
    expect(read.parallax).to eq(90.0)
    expect(read.radial_velocity).to eq(-5)
    expect(read.hr).to eq(5340)
  end

  it "reads a negative declination and a tenth of a milliarcsecond" do
    star = record(declination: -89.5, parallax: 0.4)
    records = catalog(star)

    read = records.each.first

    expect(read.declination).to be_within(1e-6).of(-89.5)
    expect(read.parallax).to eq(0.4)
  end

  it "leaves out what a star does not have" do
    records = catalog(record)

    read = records.each.first

    expect(read.proper_motion_ra).to be_nil
    expect(read.proper_motion_dec).to be_nil
    expect(read.parallax).to be_nil
    expect(read.radial_velocity).to be_nil
    expect(read.hr).to be_nil
  end

  it "counts the stars" do
    records = catalog(record, record(magnitude: 7), record(magnitude: 9))

    count = records.count

    expect(count).to eq(3)
  end

  it "keeps a star of magnitude 9 and a star brighter than magnitude 4" do
    records = catalog(
      record(magnitude: -1.46),
      record(magnitude: 9.0)
    )

    magnitudes = records.each.map(&:magnitude)

    expect(magnitudes).to contain_exactly(-1.46, 9.0)
  end

  it "reads only the stars brighter than the magnitude limit" do
    records = catalog(
      record(magnitude: -1.46),
      record(magnitude: 3.0),
      record(magnitude: 5.0),
      record(magnitude: 5.01),
      record(magnitude: 8.5)
    )

    magnitudes = records.each(magnitude_limit: 5).map(&:magnitude)

    expect(magnitudes).to contain_exactly(-1.46, 3.0, 5.0)
  end

  it "reads only the stars within a radius of a center" do
    records = catalog(
      record(right_ascension: 100, declination: 10),
      record(right_ascension: 100.9, declination: 10),
      record(right_ascension: 102, declination: 10),
      record(right_ascension: 100, declination: 11.5),
      record(right_ascension: 280, declination: -10)
    )

    stars = records.each(center: [100, 10], radius: 1).to_a

    expect(stars.map(&:right_ascension)).to contain_exactly(
      be_within(1e-6).of(100),
      be_within(1e-6).of(100.9)
    )
  end

  it "reads the stars on both sides of right ascension zero" do
    records = catalog(
      record(right_ascension: 359.5, declination: 0),
      record(right_ascension: 0.5, declination: 0),
      record(right_ascension: 2, declination: 0),
      record(right_ascension: 358, declination: 0)
    )

    stars = records.each(center: [0, 0], radius: 1).to_a

    expect(stars.map { |star| star.right_ascension.round(3) }).to eq(
      [0.5, 359.5]
    )
  end

  it "reads the stars around a pole" do
    records = catalog(
      record(right_ascension: 10, declination: 89.5),
      record(right_ascension: 190, declination: 89.5),
      record(right_ascension: 100, declination: 88)
    )

    stars = records.each(center: [0, 90], radius: 1).to_a

    expect(stars.size).to eq(2)
  end

  it "reads the stars of a cone in the order of a full read" do
    stars = Array.new(50) { |index|
      record(
        right_ascension: index * 7.2,
        declination: (index % 7) - 3,
        magnitude: 4 + index * 0.1
      )
    }
    records = catalog(*stars)

    full = records.each.select { |star|
      star.right_ascension < 24 || star.right_ascension > 336
    }
    cone = records.each(center: [0, 0], radius: 25).to_a

    expect(cone).to eq(full)
  end

  it "reads the stars with a Bright Star Catalogue number" do
    records = catalog(
      record(right_ascension: 1),
      record(right_ascension: 2, hr: 2491),
      record(right_ascension: 3, hr: 5340)
    )

    numbers = records.each_with_hr.map(&:hr)

    expect(numbers).to contain_exactly(2491, 5340)
  end

  it "reads an empty catalog" do
    records = catalog

    stars = records.each.to_a

    expect(stars).to be_empty
  end

  it "does not read data that is not a star catalog" do
    data = "not a catalog"

    expect { described_class.new(data) }.to raise_error(
      ArgumentError,
      "data is not a star catalog"
    )
  end
end
