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

  describe ".visible_runs with a view" do
    it "leaves out the points behind the view" do
      view = Skymap::View.new(
        center: equatorial(right_ascension: 0, declination: 5),
        field_of_view: 30
      )
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      behind = [
        equatorial(right_ascension: 12, declination: 5),
        equatorial(right_ascension: 12.1, declination: 5)
      ]

      runs = described_class.visible_runs(context, behind)

      expect(runs).to be_empty
    end

    it "keeps the points in front of the view" do
      view = Skymap::View.new(
        center: equatorial(right_ascension: 0, declination: 40),
        field_of_view: 30
      )
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      points = [
        equatorial(right_ascension: 0, declination: 40),
        equatorial(right_ascension: 0.1, declination: 41)
      ]

      runs = described_class.visible_runs(context, points)

      expect(runs.map(&:size)).to eq([2])
    end
  end

  describe ".line" do
    it "is a circle around the center when the whole sky is the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 90, azimuth: 0, field_of_view: 180)
      )

      line, = described_class.line(context)
      distances = line.map { |point| distance_from_center(point) }

      expect(distances.uniq).to eq([198.5])
    end

    it "is one closed line when the horizon is entirely in the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 90, azimuth: 0, field_of_view: 180)
      )

      lines = described_class.line(context)

      expect(lines.size).to eq(1)
      expect(lines.first.first).to eq(lines.first.last)
    end

    it "crosses the middle of the map when the view is centered on it" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 0, azimuth: 180, field_of_view: 30)
      )

      lines = described_class.line(context)
      middle = lines.flatten.min_by { |point| (point.x - 200).abs }

      expect(middle.y.round(2)).to eq(200)
    end

    it "leaves out the part of the horizon behind the view" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view_towards(altitude: 0, azimuth: 180, field_of_view: 30)
      )

      lines = described_class.line(context)

      expect(lines.sum(&:size)).to be < 360
    end
  end
end
