# frozen_string_literal: true

RSpec.describe Skymap::Horizon do
  describe ".visible_runs" do
    it "keeps the points above the horizon as one run" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: 40),
        equatorial(right_ascension: 4, declination: 50)
      ]

      runs = described_class.visible_runs(context, points)

      expect(runs.map(&:size)).to eq([3])
    end

    it "leaves out the points below the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: -30),
        equatorial(right_ascension: 3, declination: -40)
      ]

      runs = described_class.visible_runs(context, points)

      expect(runs).to be_empty
    end

    it "ends a run that goes below the horizon at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: -20)
      ]

      run, = described_class.visible_runs(context, points)

      expect(run.size).to eq(2)
      expect(distance_from_center(run.last)).to eq(198.5)
    end

    it "starts a run that comes back above the horizon at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: -20),
        equatorial(right_ascension: 3, declination: 30)
      ]

      run, = described_class.visible_runs(context, points)

      expect(run.size).to eq(2)
      expect(distance_from_center(run.first)).to eq(198.5)
    end

    it "splits a run that dips below the horizon in two" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: -20),
        equatorial(right_ascension: 4, declination: -20),
        equatorial(right_ascension: 4, declination: 30)
      ]

      runs = described_class.visible_runs(context, points)

      expect(runs.size).to eq(2)
    end
  end
end
