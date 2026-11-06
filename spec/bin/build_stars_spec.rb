# frozen_string_literal: true

load File.expand_path("../../bin/build_stars", __dir__)

RSpec.describe StarBuilder do
  def bright_star(right_ascension: 100.0, declination: 10.0, magnitude: 5.0)
    Skymap::Catalog::StarRecords::Record.new(
      right_ascension: right_ascension,
      declination: declination,
      magnitude: magnitude,
      proper_motion_ra: 10,
      proper_motion_dec: 20,
      parallax: nil,
      radial_velocity: nil,
      hr: 1234
    )
  end

  def tycho(**fields)
    {
      "id" => "1-2-1",
      "hip" => nil,
      "ra_deg" => "200.1",
      "de_deg" => "-10.1",
      "ra_mdeg" => "200.0",
      "de_mdeg" => "-10.0",
      "pm_ra" => "-12.4",
      "pm_de" => "5.6",
      "bt_mag" => "9.5",
      "vt_mag" => "8.5"
    }.merge(fields.transform_keys(&:to_s))
  end

  def gaia(**fields)
    {
      "id" => "1-2-1",
      "ra" => "200.0",
      "dec" => "-10.0",
      "pmra" => "-12.0",
      "pmdec" => "5.0",
      "parallax" => "7.25",
      "radial_velocity" => "-21.4",
      "number_of_neighbours" => "1"
    }.merge(fields.transform_keys(&:to_s))
  end

  def hipparcos(**fields)
    {
      "hip" => "99",
      "ra" => "200.0",
      "dec" => "-10.0",
      "pm_ra" => "-11.0",
      "pm_de" => "4.0",
      "plx" => "6.5"
    }.merge(fields.transform_keys(&:to_s))
  end

  describe ".magnitude" do
    it "converts the Tycho magnitudes to a visual magnitude" do
      row = tycho(bt_mag: "9.5", vt_mag: "8.5")

      magnitude = described_class.magnitude(row)

      expect(magnitude).to be_within(1e-9).of(8.41)
    end

    it "keeps the visual Tycho magnitude of a star without a blue one" do
      row = tycho(bt_mag: nil, vt_mag: "8.5")

      magnitude = described_class.magnitude(row)

      expect(magnitude).to eq(8.5)
    end
  end

  describe ".stars" do
    it "keeps the Bright Star Catalogue stars as they are" do
      bright = bright_star

      stars = described_class.stars([bright], [], [], [])

      expect(stars).to eq([bright])
    end

    it "adds a star with the astrometry of Tycho-2 and Gaia" do
      stars = described_class.stars([], [tycho], [gaia], [])

      star = stars.first
      expect(star.right_ascension).to eq(200.0)
      expect(star.declination).to eq(-10.0)
      expect(star.magnitude).to eq(8.41)
      expect(star.proper_motion_ra).to eq(-12)
      expect(star.proper_motion_dec).to eq(6)
      expect(star.parallax).to eq(7.3)
      expect(star.radial_velocity).to eq(-21)
      expect(star.hr).to be_nil
    end

    it "takes the parallax of Hipparcos when Gaia has none" do
      stars = described_class.stars(
        [],
        [tycho(hip: "99")],
        [gaia(parallax: nil, radial_velocity: nil)],
        [hipparcos]
      )

      star = stars.first
      expect(star.parallax).to eq(6.5)
      expect(star.radial_velocity).to be_nil
    end

    it "does not trust a Gaia match with several neighbours" do
      stars = described_class.stars(
        [],
        [tycho(hip: "99")],
        [gaia(number_of_neighbours: "2")],
        [hipparcos]
      )

      star = stars.first
      expect(star.parallax).to eq(6.5)
      expect(star.radial_velocity).to be_nil
    end

    it "leaves out what no catalog gives" do
      stars = described_class.stars([], [tycho], [], [])

      star = stars.first
      expect(star.parallax).to be_nil
      expect(star.radial_velocity).to be_nil
    end

    it "leaves out a star fainter than magnitude 9" do
      stars = described_class.stars(
        [],
        [tycho(bt_mag: "10.3", vt_mag: "9.3")],
        [],
        []
      )

      expect(stars).to be_empty
    end

    it "keeps a red star with a visual Tycho magnitude above 9" do
      stars = described_class.stars(
        [],
        [tycho(bt_mag: "12.0", vt_mag: "9.05")],
        [],
        []
      )

      expect(stars.size).to eq(1)
    end

    it "leaves out a Tycho-2 star that is in the Bright Star Catalogue" do
      bright = bright_star(
        right_ascension: 200.0,
        declination: -10.0,
        magnitude: 8.4
      )

      stars = described_class.stars([bright], [tycho], [], [])

      expect(stars).to eq([bright])
    end

    it "keeps a companion of a star of the Bright Star Catalogue" do
      bright = bright_star(
        right_ascension: 200.0,
        declination: -10.0,
        magnitude: 6.0
      )

      stars = described_class.stars([bright], [tycho], [], [])

      expect(stars.size).to eq(2)
    end

    it "matches a star that moved since the Bright Star Catalogue" do
      bright = bright_star(
        right_ascension: 200.0,
        declination: -10.0 + 14.0 / 3600,
        magnitude: 8.4
      )
      moving = tycho(pm_ra: "0", pm_de: "-3000")

      stars = described_class.stars([bright], [moving], [], [])

      expect(stars).to eq([bright])
    end

    it "takes the position at J2000 from Gaia when Tycho-2 has no mean one" do
      observed = tycho(ra_mdeg: nil, de_mdeg: nil, pm_ra: nil, pm_de: nil)
      gaia_row = gaia(ra: "200.0", dec: "-10.0", pmra: "3600000", pmdec: "0")

      stars = described_class.stars([], [observed], [gaia_row], [])

      star = stars.first
      expect(star.right_ascension).to be_within(1e-9).of(
        200.0 - 16 / Math.cos(-10 * Math::PI / 180)
      )
      expect(star.proper_motion_ra).to eq(3_600_000)
    end

    it "takes the position at J2000 from Hipparcos when Gaia has none" do
      observed = tycho(
        hip: "99",
        ra_mdeg: nil,
        de_mdeg: nil,
        pm_ra: nil,
        pm_de: nil
      )
      moving = hipparcos(pm_ra: "0", pm_de: "3600000")

      stars = described_class.stars([], [observed], [], [moving])

      star = stars.first
      expect(star.declination).to be_within(1e-9).of(-10.0 + 8.75)
    end

    it "keeps the observed position of a star no other catalog has" do
      observed = tycho(ra_mdeg: nil, de_mdeg: nil, pm_ra: nil, pm_de: nil)

      stars = described_class.stars([], [observed], [], [])

      star = stars.first
      expect(star.right_ascension).to eq(200.1)
      expect(star.proper_motion_ra).to be_nil
    end
  end

  describe ".stars near the celestial poles" do
    it "matches a star next to a star of the Bright Star Catalogue" do
      bright = bright_star(
        right_ascension: 10.0,
        declination: 89.99,
        magnitude: 8.4
      )
      offset = 2.0 / 3600 / Math.cos(89.99 * Math::PI / 180)
      neighbor = tycho(
        ra_mdeg: (10.0 + offset).to_s,
        de_mdeg: "89.99",
        pm_ra: "0",
        pm_de: "0"
      )

      stars = described_class.stars([bright], [neighbor], [], [])

      expect(stars).to eq([bright])
    end

    it "keeps a star a degree away" do
      bright = bright_star(
        right_ascension: 10.0,
        declination: 89.99,
        magnitude: 8.4
      )
      far = tycho(ra_mdeg: "190.0", de_mdeg: "89.99")

      stars = described_class.stars([bright], [far], [], [])

      expect(stars.size).to eq(2)
    end
  end

  describe ".sources" do
    def csv(*names)
      "id,hip\n#{names.join("\n")}\n"
    end

    it "downloads each source once and reads it again from the directory" do
      directory = Dir.mktmpdir
      allow(described_class).to receive(:query).and_return(csv("1,2"))

      described_class.sources(directory)
      described_class.sources(directory)

      expect(described_class).to have_received(:query).exactly(3).times
    end

    it "downloads a source again when its query changes" do
      directory = Dir.mktmpdir
      allow(described_class).to receive(:query).and_return(csv("1,2"))
      described_class.sources(directory)
      stub_const(
        "StarBuilder::SOURCES",
        described_class::SOURCES.transform_values { |adql| "#{adql} " }
      )

      described_class.sources(directory)

      expect(described_class).to have_received(:query).exactly(6).times
    end

    it "keeps no file for a download that failed" do
      directory = Dir.mktmpdir
      allow(described_class).to receive(:query).and_raise("The request failed")

      expect { described_class.sources(directory) }.to raise_error(/failed/)

      expect(Dir.children(directory)).to be_empty
    end

    it "reads the sources by name" do
      directory = Dir.mktmpdir
      allow(described_class).to receive(:query).and_return(csv("1,2"))

      sources = described_class.sources(directory)

      expect(sources.keys).to eq(%w[tycho2 gaia hipparcos])
      expect(sources["tycho2"].first["id"]).to eq("1")
    end
  end

  describe ".get" do
    it "raises when the archive does not answer with a success" do
      response = Net::HTTPServiceUnavailable.new("1.1", "503", "Busy")
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect {
        described_class.send(:get, URI("https://example.test/tap/phase"))
      }.to raise_error(/503/)
    end

    it "gives the body of a success" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("COMPLETED")
      allow(Net::HTTP).to receive(:start).and_return(response)

      body = described_class.send(:get, URI("https://example.test/tap/phase"))

      expect(body).to eq("COMPLETED")
    end
  end

  describe ".bright_stars" do
    it "reads the stars of the Bright Star Catalogue" do
      stars = described_class.bright_stars

      sirius = stars.find { |star| star.hr == 2491 }
      expect(stars.size).to eq(9096)
      expect(sirius.right_ascension).to be_within(1e-6).of(6.752472 * 15)
      expect(sirius.parallax).to eq(375)
    end
  end

  describe ".write" do
    it "writes a file the catalog reads" do
      path = File.join(Dir.mktmpdir, "stars.bin")

      described_class.write([bright_star], path)

      records = Skymap::Catalog::StarRecords.new(File.binread(path))
      expect(records.each.map(&:hr)).to eq([1234])
    end
  end
end
