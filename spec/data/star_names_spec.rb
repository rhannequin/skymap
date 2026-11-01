# frozen_string_literal: true

require "csv"

RSpec.describe "data/star_names.csv" do
  def named_stars
    CSV.read(Skymap::Catalog::StarNames::PATH, headers: true)
      .map { |row| row["hr"].to_i }
  end

  it "names 333 stars" do
    count = named_stars.size

    expect(count).to eq(333)
  end

  it "joins stars of the star catalog" do
    stars = Skymap::Catalog::Stars.new.map(&:hr)

    unknown = named_stars - stars

    expect(unknown).to be_empty
  end

  it "names each star once" do
    duplicated = named_stars.tally.select { |_hr, count| count > 1 }

    expect(duplicated).to be_empty
  end
end
