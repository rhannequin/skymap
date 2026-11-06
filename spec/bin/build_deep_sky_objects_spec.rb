# frozen_string_literal: true

load File.expand_path("../../bin/build_deep_sky_objects", __dir__)

RSpec.describe DeepSkyObjectBuilder do
  def columns
    [
      "Name", "Type", "RA", "Dec", "Const", "MajAx", "MinAx", "PosAng",
      "B-Mag", "V-Mag", "J-Mag", "H-Mag", "K-Mag", "SurfBr", "Hubble", "Pax",
      "Pm-RA", "Pm-Dec", "RadVel", "Redshift", "Cstar U-Mag", "Cstar B-Mag",
      "Cstar V-Mag", "M", "NGC", "IC", "Cstar Names", "Identifiers",
      "Common names", "NED notes", "OpenNGC notes", "Sources"
    ]
  end

  def record(**fields)
    values = {
      "Name" => "NGC0224",
      "Type" => "G",
      "RA" => "00:42:44.35",
      "Dec" => "+41:16:08.6",
      "MajAx" => "177.83",
      "MinAx" => "69.66",
      "PosAng" => "35",
      "B-Mag" => "4.29",
      "V-Mag" => "3.44",
      "M" => "031",
      "Common names" => "Andromeda Galaxy"
    }.merge(
      fields.transform_keys do |key|
        key.to_s.tr("_", " ").sub(/\A([BV]) Mag\z/, '\1-Mag')
      end
    )

    described_class.parse(
      CSV.generate(col_sep: ";") do |csv|
        csv << columns
        csv << columns.map { |column| values[column] }
      end
    ).first
  end

  describe ".parse" do
    it "reads semicolon-separated records" do
      content = "#{columns.join(";")}\n#{columns.map { "x" }.join(";")}\n"

      records = described_class.parse(content)

      expect(records.size).to eq(1)
      expect(records.first["Name"]).to eq("x")
    end

    it "fails when a column is missing" do
      content = "Name;Type\nNGC0224;G\n"

      expect { described_class.parse(content) }.to raise_error(
        ArgumentError,
        /missing columns: .*RA/
      )
    end
  end

  describe ".records" do
    it "reads the catalog and the addendum of a directory" do
      directory = Dir.mktmpdir
      header = "#{columns.join(";")}\n"
      File.write(File.join(directory, "NGC.csv"), "#{header}NGC0224\n")
      File.write(File.join(directory, "addendum.csv"), "#{header}M040\n")

      records = described_class.records(directory)

      expect(records.map { |record| record["Name"] }).to eq(%w[NGC0224 M040])
    end
  end

  describe ".selected?" do
    it "keeps an object with a Messier number" do
      expect(described_class.selected?(record)).to be(true)
    end

    it "keeps a faint object with a Messier number" do
      expect(described_class.selected?(record(V_Mag: "13.5"))).to be(true)
    end

    it "keeps an NGC object of magnitude 12" do
      object = record(Name: "NGC0869", M: nil, V_Mag: "12.0")

      expect(described_class.selected?(object)).to be(true)
    end

    it "keeps an IC object that has only a blue magnitude" do
      object = record(Name: "IC0434", M: nil, V_Mag: "", B_Mag: "11.0")

      expect(described_class.selected?(object)).to be(true)
    end

    it "leaves out an NGC object fainter than magnitude 12" do
      object = record(Name: "NGC0001", M: nil, V_Mag: "12.1")

      expect(described_class.selected?(object)).to be(false)
    end

    it "leaves out an NGC object without a magnitude" do
      object = record(Name: "NGC0281", M: nil, V_Mag: "", B_Mag: "")

      expect(described_class.selected?(object)).to be(false)
    end

    it "leaves out a component of a galaxy, such as NGC 520 NED01" do
      object = record(Name: "NGC0520 NED01", M: nil, V_Mag: "10")

      expect(described_class.selected?(object)).to be(false)
    end

    it "leaves out objects of a type that is not an object of the sky" do
      types = %w[Dup NonEx * Nova DrkN].map do |type|
        described_class.selected?(record(Name: "NGC0001", M: nil, Type: type))
      end

      expect(types).to all(be(false))
    end

    it "leaves out an object of another catalog" do
      object = record(Name: "C009", M: nil, V_Mag: "5.0")

      expect(described_class.selected?(object)).to be(false)
    end

    it "leaves out a duplicate, such as M102" do
      expect(described_class.selected?(record(Type: "Dup", M: "101")))
        .to be(false)
    end
  end

  describe ".row" do
    it "converts an object to a row" do
      row = described_class.row(record)

      expect(row).to eq(
        ["M31", "Andromeda Galaxy", "galaxy", 0.712319, 41.269056, 3.44, "V",
          177.83, 69.66, 35.0]
      )
    end

    it "leaves unknown values blank" do
      row = described_class.row(
        record(
          Name: "M040", Type: "**", MajAx: "", MinAx: "", PosAng: "",
          B_Mag: "", V_Mag: "8.00", M: "040", Common_names: ""
        )
      )

      expect(row).to eq(
        ["M40", nil, "double_star", 0.712319, 41.269056, 8.0, "V", nil, nil,
          nil]
      )
    end

    it "uses the B magnitude when there is no V magnitude" do
      row = described_class.row(record(V_Mag: "", B_Mag: "4.29"))

      expect(row[5]).to eq(4.29)
      expect(row[6]).to eq("B")
    end

    it "leaves the magnitude blank when there is none" do
      row = described_class.row(record(V_Mag: "", B_Mag: ""))

      expect(row[5]).to be_nil
      expect(row[6]).to be_nil
    end

    it "keeps the first common name" do
      row = described_class.row(
        record(Common_names: "Beehive,Praesepe Cluster")
      )

      expect(row[1]).to eq("Beehive")
    end
  end

  describe ".designation" do
    it "names a Messier object after its number, without zero padding" do
      expect(described_class.designation(record(M: "001"))).to eq("M1")
      expect(described_class.designation(record(M: "110"))).to eq("M110")
    end

    it "names an NGC object without zero padding" do
      designation = described_class.designation(record(M: nil))

      expect(designation).to eq("NGC 224")
    end

    it "names an IC object without zero padding" do
      designation = described_class.designation(record(Name: "IC0434", M: nil))

      expect(designation).to eq("IC 434")
    end

    it "keeps the letter of an NGC object" do
      designation = described_class.designation(
        record(Name: "NGC0224A", M: nil)
      )

      expect(designation).to eq("NGC 224A")
    end

    it "fails for another catalog" do
      expect {
        described_class.designation(record(Name: "Mel022", M: nil))
      }.to raise_error(ArgumentError, 'unknown designation: "Mel022"')
    end
  end

  describe ".type" do
    it "maps the OpenNGC types to the types of Skymap::DeepSkyObject" do
      {
        "G" => "galaxy",
        "GPair" => "galaxy",
        "GTrpl" => "galaxy",
        "GGroup" => "galaxy",
        "OCl" => "open_cluster",
        "GCl" => "globular_cluster",
        "PN" => "planetary_nebula",
        "Neb" => "nebula",
        "HII" => "nebula",
        "EmN" => "nebula",
        "RfN" => "nebula",
        "Cl+N" => "nebula",
        "SNR" => "supernova_remnant",
        "*Ass" => "asterism",
        "**" => "double_star",
        "Other" => "other"
      }.each do |code, type|
        expect(described_class.type(record(Type: code))).to eq(type)
      end
    end

    it "only gives types the value object accepts" do
      types = described_class::TYPES.values.uniq.map(&:to_sym)

      expect(types - Skymap::DeepSkyObject::TYPES).to be_empty
    end

    it "fails on an unknown type" do
      expect { described_class.type(record(Type: "DrkN")) }.to raise_error(
        ArgumentError,
        'unknown type "DrkN" for NGC0224'
      )
    end
  end

  describe ".right_ascension and .declination" do
    it "converts sexagesimal coordinates to decimals" do
      expect(described_class.right_ascension("05:34:31.94")).to eq(5.575539)
      expect(described_class.declination("+22:00:52.2")).to eq(22.014500)
    end

    it "keeps the sign of a declination between 0 and -1 degree" do
      expect(described_class.declination("-00:30:00")).to eq(-0.5)
    end

    it "converts a negative declination" do
      expect(described_class.declination("-05:23:28.0")).to eq(-5.391111)
    end
  end

  describe ".rows" do
    it "keeps the Messier objects and the bright NGC and IC objects, sorted" do
      records = [
        record(Name: "NGC0598", M: "033"),
        record(Name: "IC0005", M: nil, V_Mag: "11"),
        record(Name: "NGC0001", M: nil, V_Mag: "15"),
        record(Name: "M102", Type: "Dup", M: "101"),
        record(Name: "NGC1952", M: "001"),
        record(Name: "NGC0869", M: nil, V_Mag: "3.7"),
        record(Name: "NGC0224", M: "031")
      ]

      rows = described_class.rows(records)

      expect(rows.map(&:first)).to eq(["M1", "M31", "M33", "NGC 869", "IC 5"])
    end
  end

  describe ".sort_key" do
    it "sorts Messier objects before NGC and IC objects, by number" do
      designations = ["IC 5", "NGC 10", "M31", "NGC 9", "M5", "NGC 9A"]

      sorted = designations.sort_by { |name| described_class.sort_key(name) }

      expect(sorted).to eq(["M5", "M31", "NGC 9", "NGC 9A", "NGC 10", "IC 5"])
    end
  end

  describe ".write" do
    it "writes the rows with blanks for unknown values" do
      path = File.join(Dir.mktmpdir, "deep_sky_objects.csv")
      rows = [
        described_class.row(record),
        described_class.row(
          record(
            Name: "M040", Type: "**", MajAx: "", MinAx: "", PosAng: "",
            V_Mag: "8.00", M: "040", Common_names: ""
          )
        )
      ]

      described_class.write(rows, path)

      expect(File.read(path)).to eq(<<~CSV)
        designation,name,type,right_ascension,declination,magnitude,magnitude_band,major_axis,minor_axis,position_angle
        M31,Andromeda Galaxy,galaxy,0.712319,41.269056,3.44,V,177.83,69.66,35.0
        M40,,double_star,0.712319,41.269056,8.0,V,,,
      CSV
    end
  end
end
