# frozen_string_literal: true

RSpec.describe Skymap::Catalog::Stars do
  def cone_around(right_ascension_hours, declination, radius)
    Skymap::Cone.new(
      center: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(right_ascension_hours),
        declination: Astronoby::Angle.from_degrees(declination),
        epoch: Astronoby::JulianDate::J2000
      ),
      radius: Astronoby::Angle.from_degrees(radius)
    )
  end

  it "loads every star of the catalog" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(130_556)
  end

  it "gives an enumerator without a block" do
    catalog = described_class.new

    first = catalog.each.next

    expect(first).to be_a(Skymap::Star)
  end

  it "reads the identifier, J2000 coordinates and magnitude of each star" do
    catalog = described_class.new

    sirius = catalog.by_hr.fetch(2491)
    coordinates = sirius.equatorial_coordinates

    expect(coordinates.right_ascension.hours.round(6)).to eq(6.752472)
    expect(coordinates.declination.degrees.round(6)).to eq(-16.716111)
    expect(coordinates.epoch).to eq(Astronoby::JulianDate::J2000)
    expect(sirius.magnitude).to eq(-1.46)
  end

  it "reads the proper motion, parallax and radial velocity of a star" do
    catalog = described_class.new

    arcturus = catalog.by_hr.fetch(5340)

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

    star = catalog.by_hr.fetch(1630)

    expect(star.proper_motion_ra).not_to be_nil
    expect(star.parallax).to be_nil
    expect(star.radial_velocity).to be_nil
  end

  describe "#by_hr" do
    it "gives the 9,096 stars of the Bright Star Catalogue" do
      catalog = described_class.new

      stars = catalog.by_hr

      expect(stars.size).to eq(9096)
      expect(stars.keys).to all(be_between(1, 9110))
    end

    it "gives the same stars each time" do
      catalog = described_class.new

      first = catalog.by_hr
      second = catalog.by_hr

      expect(second).to equal(first)
    end

    it "gives the stars that a search gives" do
      catalog = described_class.new

      sirius = catalog.by_hr.fetch(2491)
      found = catalog.search(magnitude_limit: 2).find { |star| star.hr == 2491 }

      expect(found).to equal(sirius)
    end
  end

  describe "#search" do
    it "gives the stars brighter than the magnitude limit" do
      catalog = described_class.new

      stars = catalog.search(magnitude_limit: 3)

      expect(stars.size).to eq(176)
      expect(stars.map(&:magnitude).max).to be <= 3
    end

    it "gives the stars of a cone" do
      catalog = described_class.new
      m87 = cone_around(12.5137, 12.391, 1)

      stars = catalog.search(magnitude_limit: 9, cone: m87)

      expect(stars.size).to eq(7)
      expect(stars.map(&:hr)).to all(be_nil)
    end

    it "gives the stars brighter than 9 of a cone with their astrometry" do
      catalog = described_class.new
      m87 = cone_around(12.5137, 12.391, 1)

      star = catalog.search(magnitude_limit: 9, cone: m87)
        .find { |candidate| (candidate.magnitude - 7.88).abs < 0.001 }

      expect(star.proper_motion_ra.mas_per_year.round).to eq(-52)
      expect(star.parallax.degree_milliarcseconds.round(1)).to eq(2.2)
      expect(star.radial_velocity.kmps).to eq(-5)
    end

    it "gives the same stars as a full read" do
      catalog = described_class.new
      cone = cone_around(0.1, 3, 4)

      found = catalog.search(magnitude_limit: 8, cone: cone)
      expected = catalog.select do |star|
        star.magnitude <= 8 &&
          separation_in_degrees(star.equatorial_coordinates, cone.center) <=
            cone.radius.degrees
      end

      expect(found.map { |star|
        star.equatorial_coordinates.declination.radians
      })
        .to match_array(
          expected.map { |star|
            star.equatorial_coordinates.declination.radians
          }
        )
    end

    it "gives the same stars each time for the whole sky" do
      catalog = described_class.new

      first = catalog.search(magnitude_limit: 5)
      second = catalog.search(magnitude_limit: 5)

      expect(second.map(&:object_id)).to eq(first.map(&:object_id))
    end

    it "builds a star once for the magnitude limits that include it" do
      catalog = described_class.new

      five = catalog.search(magnitude_limit: 5)
      six = catalog.search(magnitude_limit: 6)
        .to_h { |star| [star.object_id, star] }

      expect(five.size).to be > 1000
      expect(five.map(&:object_id)).to all(satisfy { |id| six.key?(id) })
    end

    it "does not remember the stars of a cone" do
      catalog = described_class.new
      m87 = cone_around(12.5137, 12.391, 1)

      first = catalog.search(magnitude_limit: 9, cone: m87)
      second = catalog.search(magnitude_limit: 9, cone: m87)

      expect(second).not_to be(first)
    end

    it "gives every star without a limit or a cone" do
      catalog = described_class.new

      stars = catalog.search

      expect(stars.size).to eq(130_556)
    end
  end
end
