# frozen_string_literal: true

RSpec.describe Skymap::Layers::Grid do
  describe "#elements" do
    it "draws the circles of declination around the celestial pole" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      grids = layer.elements(context)
      circles = grids.select { |grid| grid.points.first == grid.points.last }
      radii = circles.map { |circle|
        circle.points.sum { |point| distance_from_center(point) } /
          circle.points.size
      }

      expect(radii).to include(be_within(1).of(53.19), be_within(1).of(114.6))
    end

    it "draws a line of right ascension every step" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      default = described_class.new.elements(context)
      quarters = described_class.new(step: degrees(90)).elements(context)
      fine = described_class.new(step: degrees(15)).elements(context)

      expect([default, quarters, fine].map { |grids| at_the_pole(grids) })
        .to eq([12, 4, 24])
    end

    it "lands the lines on the same angles however the step is built" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      steps = [
        degrees(15),
        Astronoby::Angle.from_hours(1),
        Astronoby::Angle.from_dms(15, 0, 0)
      ]

      renders = steps.map { |step|
        described_class.new(step: step).elements(context).map(&:points)
      }

      expect(renders.uniq.size).to eq(1)
      expect(at_the_pole(described_class.new(step: steps[1]).elements(context)))
        .to eq(24)
    end

    it "draws lines every 7.5 degrees" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      step = Astronoby::Angle.from_dms(7, 30, 0)

      grids = described_class.new(step: step).elements(context)

      expect(at_the_pole(grids)).to eq(48)
    end

    it "stops the lines at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      distances = layer.elements(context).flat_map do |grid|
        grid.points.map { |point| distance_from_center(point) }
      end

      expect(distances.max).to eq(198.5)
    end

    it "draws a parallel that crosses the horizon as one line" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(step: degrees(90))

      grids = layer.elements(context)
      starts = grids.map { |grid| grid.points.first }
      ends = grids.map { |grid| grid.points.last }

      expect(starts & ends).to be_empty
    end

    it "draws a thin line that scales with the canvas" do
      layer = described_class.new
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )

      small_grid, = layer.elements(small)
      large_grid, = layer.elements(large)

      expect(small_grid.width).to be < 1
      expect(large_grid.width).to eq(small_grid.width * 2)
    end
  end

  describe "#elements with an epoch" do
    it "draws the same lines by default as with the J2000 epoch" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      default = described_class.new.elements(context)
      j2000 = described_class.new(epoch: :j2000).elements(context)

      expect(default.map(&:points)).to eq(j2000.map(&:points))
    end

    it "centers the circles of declination on the pole of date" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      of_date = circle_distances(
        described_class.new(epoch: :of_date).elements(context)
      )
      j2000 = circle_distances(described_class.new.elements(context))

      expect(of_date.max - of_date.min).to be < 0.01
      expect(j2000.max - j2000.min).to be > 0.5
    end

    it "draws the same number of lines as with J2000" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      of_date = described_class.new(epoch: :of_date).elements(context)
      j2000 = described_class.new.elements(context)

      expect(of_date.size).to eq(j2000.size)
    end

    it "draws each instant with its own epoch from the same grid" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      first = context_on(Time.utc(2026, 9, 24, 22), canvas)
      second = context_on(Time.utc(2036, 3, 1, 4), canvas)
      layer = described_class.new(step: degrees(15), epoch: :of_date)

      first_render = layer.elements(first)
      second_render = layer.elements(second)
      first_again = layer.elements(first)
      second_fresh = described_class.new(step: degrees(15), epoch: :of_date)
        .elements(second)

      expect(first_render.map(&:points)).not_to eq(second_render.map(&:points))
      expect(first_again.map(&:points)).to eq(first_render.map(&:points))
      expect(second_render.map(&:points)).to eq(second_fresh.map(&:points))
    end

    it "draws the same lines through both epochs at the J2000 instant" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      context = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_terrestrial_time(
          Astronoby::JulianDate::J2000
        ),
        canvas: canvas
      )

      j2000 = described_class.new.elements(context)
      of_date = described_class.new(epoch: :of_date).elements(context)

      expect(of_date.map(&:points)).to eq(j2000.map(&:points))
    end

    it "draws the lines of date in a zoomed view" do
      view = view_towards(altitude: 48.8575, azimuth: 0, field_of_view: 20)
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )

      layer = described_class.new(step: degrees(5), epoch: :of_date)

      grids = layer.elements(context)

      expect(grids).not_to be_empty
    end
  end

  describe "#elements in a zoomed view" do
    views = {
      "near the celestial pole" => [[22, 89], 4, [15, 1], {}],
      "on the celestial equator" => [[22, 0], 10, [15, 1], {}],
      "across right ascension 0h" => [[0, 20], 30, [15, 1], {}],
      "in the equatorial orientation, rotated" => [
        [1, 30], 12, [15, 1], {orientation: :equatorial, rotation: 30}
      ],
      "of half a degree" => [[0, 0], 0.5, [15, 1], {on_the_grid_epoch: true}],
      "of 90 degrees" => [[22, 40], 90, [15], {}],
      "of 180 degrees" => [[22, 40], 180, [15], {}]
    }

    views.each do |name, (center, field_of_view, steps, options)|
      %i[j2000 of_date].product(steps).each do |epoch, step|
        it "keeps every line that reaches a view #{name} " \
          "(#{epoch}, every #{step} degrees)" do
          instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22))
          view = view_on(
            center,
            field_of_view,
            epoch: (options[:on_the_grid_epoch] && epoch == :of_date) ?
              instant.tt : Astronoby::JulianDate::J2000,
            **options.slice(:orientation, :rotation)
          )
          context = context_at(
            latitude: 48.8575,
            canvas: Skymap::Canvas.new(size: 800, padding: 24),
            view: view
          )
          layer = described_class.new(step: degrees(step), epoch: epoch)

          grids = layer.elements(context)
          drawn = grids.flat_map(&:points)
          reaching = lines_in_view(context, step, epoch)
          dropped = reaching.select { |points| (points - drawn).any? }

          expect(grids).not_to be_empty
          expect(reaching).not_to be_empty
          expect(dropped).to be_empty
        end
      end
    end
  end

  describe ".new" do
    it "rejects an unknown epoch" do
      expect { described_class.new(epoch: :b1950) }
        .to raise_error(ArgumentError, /epoch must be :j2000 or :of_date/)
    end

    it "rejects an epoch that is not a symbol" do
      expect { described_class.new(epoch: "of_date") }
        .to raise_error(ArgumentError, /epoch must be/)
    end

    it "rejects a step that is not an angle" do
      expect { described_class.new(step: 15) }
        .to raise_error(ArgumentError, /step must be an Astronoby::Angle/)
    end

    it "rejects a step that does not divide the circle" do
      expect { described_class.new(step: degrees(7)) }
        .to raise_error(ArgumentError, /divides 360 degrees/)
    end

    it "rejects a step of zero" do
      expect { described_class.new(step: Astronoby::Angle.zero) }
        .to raise_error(ArgumentError, /between 1 and 90 degrees/)
    end

    it "rejects a negative step" do
      expect { described_class.new(step: degrees(-15)) }
        .to raise_error(ArgumentError, /between 1 and 90 degrees/)
    end

    it "rejects a step below 1 degree" do
      expect { described_class.new(step: degrees(0.5)) }
        .to raise_error(ArgumentError, /between 1 and 90 degrees/)
    end

    it "rejects a step above 90 degrees" do
      expect { described_class.new(step: degrees(120)) }
        .to raise_error(ArgumentError, /between 1 and 90 degrees/)
    end
  end

  def degrees(value)
    Astronoby::Angle.from_degrees(value)
  end

  def view_on(
    center,
    field_of_view,
    epoch:,
    rotation: 0,
    orientation: :zenith_up
  )
    Skymap::View.new(
      center: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(center[0]),
        declination: degrees(center[1]),
        epoch: epoch
      ),
      field_of_view: degrees(field_of_view),
      orientation: orientation,
      rotation: degrees(rotation)
    )
  end

  def lines_in_view(context, step, epoch)
    j2000 = Astronoby::JulianDate::J2000
    frame = (epoch == :j2000) ? j2000 : context.instant.tt
    parallels = (-89..89).select { |declination| (declination % step).zero? }
      .map { |declination|
        (0...360).map { |right_ascension| [right_ascension, declination] }
      }
    meridians = (0...360).step(step).map { |right_ascension|
      (-90..90).map { |declination| [right_ascension, declination] }
    }

    (parallels + meridians).filter_map do |samples|
      points = samples.filter_map { |right_ascension, declination|
        projected_in_view(context, right_ascension, declination, frame)
      }
      points unless points.empty?
    end
  end

  def projected_in_view(context, right_ascension, declination, epoch)
    horizontal = context.horizontal_coordinates(
      Astronoby::Coordinates::Equatorial.new(
        right_ascension: degrees(right_ascension),
        declination: degrees(declination),
        epoch: epoch
      )
    )
    return if horizontal.altitude.negative?

    point = context.project(
      altitude: horizontal.altitude,
      azimuth: horizontal.azimuth
    )
    point if context.in_view?(point)
  end

  def context_on(time, canvas)
    Skymap::Context.new(
      observer: observer_at(latitude: 48.8575),
      instant: Astronoby::Instant.from_time(time),
      canvas: canvas
    )
  end

  def circle_distances(grids)
    circle = grids.find { |grid| grid.points.first == grid.points.last }

    circle.points.map { |point| distance_from_center(point) }
  end

  def at_the_pole(grids)
    grids.count do |grid|
      grid.points.any? { |point| distance_from_center(point) < 2 }
    end
  end
end
