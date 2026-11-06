# frozen_string_literal: true

load File.expand_path("../../bin/build_catalog", __dir__)

RSpec.describe CatalogBuilder do
  def record(
    hr: "5340",
    proper_motion_ra: "-1.093",
    proper_motion_dec: "-1.998",
    parallax: " .090",
    radial_velocity: "  -5"
  )
    line = " " * 197
    {
      [1, 4] => hr.rjust(4),
      [76, 83] => "14 15 39.7".delete(" ").rjust(8),
      [84, 90] => "+191057",
      [103, 107] => "-0.04".rjust(5),
      [149, 154] => proper_motion_ra.rjust(6),
      [155, 160] => proper_motion_dec.rjust(6),
      [162, 166] => parallax.rjust(5),
      [167, 170] => radial_velocity.rjust(4)
    }.each do |(first, last), value|
      line[(first - 1)..(last - 1)] = value
    end
    line
  end

  describe ".row" do
    it "converts the proper motion and the parallax to milliarcseconds" do
      row = described_class.row(record)

      expect(row.first(4)).to eq([5340, 14.261028, 19.182500, -0.04])
      expect(row.drop(4)).to eq([-1093, -1998, 90, -5])
    end

    it "leaves the parallax blank when it is blank" do
      row = described_class.row(record(parallax: ""))

      expect(row[6]).to be_nil
    end

    it "leaves the parallax blank when it is zero" do
      row = described_class.row(record(parallax: "0.000"))

      expect(row[6]).to be_nil
    end

    it "leaves the parallax blank when it is negative" do
      row = described_class.row(record(parallax: "-.012"))

      expect(row[6]).to be_nil
    end

    it "leaves the radial velocity blank when it is blank" do
      row = described_class.row(record(radial_velocity: ""))

      expect(row[7]).to be_nil
    end

    it "keeps a radial velocity of zero" do
      row = described_class.row(record(radial_velocity: "0"))

      expect(row[7]).to eq(0)
    end

    it "keeps a proper motion of zero" do
      row = described_class.row(
        record(proper_motion_ra: "0.000", proper_motion_dec: "-.025")
      )

      expect(row[4..5]).to eq([0, -25])
    end

    it "leaves both proper motions blank when one is blank" do
      row = described_class.row(record(proper_motion_dec: ""))

      expect(row[4..5]).to eq([nil, nil])
    end

    it "skips an entry without coordinates" do
      line = record
      line[75..82] = " " * 8

      expect(described_class.row(line)).to be_nil
    end
  end

  describe ".write" do
    it "writes the rows with blanks for unknown values" do
      path = File.join(Dir.mktmpdir, "stars.csv")
      rows = [described_class.row(record(parallax: "", radial_velocity: ""))]

      described_class.write(rows, path)

      expect(File.read(path)).to eq(<<~CSV)
        hr,right_ascension,declination,magnitude,proper_motion_ra,proper_motion_dec,parallax,radial_velocity
        5340,14.261028,19.1825,-0.04,-1093,-1998,,
      CSV
    end
  end
end
