# frozen_string_literal: true

RSpec.describe Skymap::Layers::Moon do
  describe "#elements" do
    it "draws the Moon where it is in the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect(moon.center.x.round(1)).to eq(183.4)
      expect(moon.center.y.round(1)).to eq(306.5)
    end

    it "lights the part of the Moon that faces the Sun" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect(moon.illuminated_fraction.round(3)).to eq(0.964)
    end

    it "turns the lit side of the Moon toward the Sun on the map" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect((moon.rotation % 360).round).to eq(23)
    end

    it "turns the lit side with the position of the Moon in the sky" do
      observer = Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(48.8575),
        longitude: Astronoby::Angle.from_degrees(2.3514)
      )
      context = Skymap::Context.new(
        observer: observer,
        instant: Astronoby::Instant.from_time(Time.utc(2026, 10, 3, 3)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect((moon.rotation % 360).round).to eq(202)
    end

    it "draws the Moon with a size that follows the canvas" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris)

      small_moon, = layer.elements(small)
      large_moon, = layer.elements(large)

      expect(small_moon.radius).to eq(6)
      expect(large_moon.radius).to eq(12)
    end

    it "leaves out the Moon below the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moons = layer.elements(context)

      expect(moons).to be_empty
    end
  end

  describe "#elements when zoomed on the Moon" do
    it "draws the Moon at its size in the sky once that is larger" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 17, 30))
      observer = observer_at(latitude: 48.8575)
      moon = Astronoby::Moon.at(instant, ephem: ephemeris)
        .observed_by(observer).horizontal
      view = Skymap::View.new(
        center: moon,
        field_of_view: Astronoby::Angle.from_degrees(2)
      )
      context = Skymap::Context.new(
        observer: observer,
        instant: instant,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      layer = described_class.new(ephem: ephemeris)

      drawn, = layer.elements(context)

      expect(drawn.radius).to be > 0.03 * 198.5 * 5
    end
  end

  describe "#elements toward the Sun" do
    it "points the lit side at the Sun in the whole sky" do
      context = context_toward_the_moon(nil)

      moon, = described_class.new(ephem: ephemeris).elements(context)

      expect(angle_difference(moon.rotation, toward_the_sun(context, moon)))
        .to be < 1
    end

    it "points the lit side at the Sun for a Moon off the center of a view" do
      view = Skymap::View.new(
        center: near_the_moon,
        field_of_view: Astronoby::Angle.from_degrees(40),
        orientation: :equatorial
      )
      context = context_toward_the_moon(view)

      moon, = described_class.new(ephem: ephemeris).elements(context)

      expect(angle_difference(moon.rotation, toward_the_sun(context, moon)))
        .to be < 1
    end

    it "points the lit side at the Sun in a turned and mirrored view" do
      view = Skymap::View.new(
        center: near_the_moon,
        field_of_view: Astronoby::Angle.from_degrees(40),
        orientation: :equatorial,
        rotation: Astronoby::Angle.from_degrees(30),
        mirrored: true
      )
      context = context_toward_the_moon(view)

      moon, = described_class.new(ephem: ephemeris).elements(context)

      expect(angle_difference(moon.rotation, toward_the_sun(context, moon)))
        .to be < 1
    end
  end

  describe "#elements with an orientation" do
    it "follows the north in an equatorial orientation" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 17, 30))
      observer = observer_at(latitude: 48.8575)
      moon = Astronoby::Moon.at(instant, ephem: ephemeris)
      horizontal = moon.observed_by(observer).horizontal
      parallactic = moon.parallactic_angle(observer: observer).degrees

      from_zenith = rotation_with(instant, observer, horizontal, :zenith_up)
      from_north = rotation_with(instant, observer, horizontal, :equatorial)

      expect(from_north).to be_within(1e-9).of(from_zenith - parallactic)
    end

    it "turns the lit side with the rotation of the view" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 17, 30))
      observer = observer_at(latitude: 48.8575)
      horizontal = Astronoby::Moon.at(instant, ephem: ephemeris)
        .observed_by(observer).horizontal

      upright = rotation_with(instant, observer, horizontal, :zenith_up)
      turned = rotation_with(
        instant,
        observer,
        horizontal,
        :zenith_up,
        rotation: Astronoby::Angle.from_degrees(180)
      )

      expect(turned).to be_within(1e-9).of(upright + 180)
    end

    it "swaps the lit side in a mirrored view" do
      instant = Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 17, 30))
      observer = observer_at(latitude: 48.8575)
      horizontal = Astronoby::Moon.at(instant, ephem: ephemeris)
        .observed_by(observer).horizontal

      upright = rotation_with(instant, observer, horizontal, :zenith_up)
      mirrored = rotation_with(
        instant, observer, horizontal, :zenith_up, mirrored: true
      )

      expect(upright + mirrored).to be_within(1e-9).of(-180)
    end
  end

  def context_toward_the_moon(view)
    Skymap::Context.new(
      observer: moon_observer,
      instant: moon_instant,
      canvas: Skymap::Canvas.new(size: 800, padding: 24),
      view: view
    )
  end

  def moon_observer
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(48.8575),
      longitude: Astronoby::Angle.from_degrees(2.3514)
    )
  end

  def moon_instant
    Astronoby::Instant.from_time(Time.utc(2026, 10, 15, 15))
  end

  def near_the_moon
    moon = Astronoby::Moon.at(moon_instant, ephem: ephemeris)
      .observed_by(moon_observer).horizontal

    Astronoby::Coordinates::Horizontal.new(
      altitude: Astronoby::Angle.from_degrees(moon.altitude.degrees + 8),
      azimuth: Astronoby::Angle.from_degrees(moon.azimuth.degrees - 6),
      observer: moon_observer
    )
  end

  def toward_the_sun(context, moon)
    horizontal = Astronoby::Moon.at(moon_instant, ephem: ephemeris)
      .observed_by(moon_observer).horizontal
    sun = Astronoby::Sun.at(moon_instant, ephem: ephemeris)
      .observed_by(moon_observer).horizontal
    from = direction_of(horizontal)
    to = direction_of(sun)
    along = from.zip(to).sum { |a, b| a * b }
    step = to.zip(from).map { |b, a| b - along * a }
    length = Math.sqrt(step.sum { |component| component**2 })
    nearby = from.zip(step).map { |a, b| a + 1e-3 * b / length }
    point = context.project(
      altitude: Astronoby::Angle.from_radians(Math.asin(nearby[2])),
      azimuth: Astronoby::Angle.from_radians(Math.atan2(nearby[1], nearby[0]))
    )

    Math.atan2(point.y - moon.center.y, point.x - moon.center.x) *
      180 / Math::PI
  end

  def direction_of(horizontal)
    [
      horizontal.altitude.cos * horizontal.azimuth.cos,
      horizontal.altitude.cos * horizontal.azimuth.sin,
      horizontal.altitude.sin
    ]
  end

  def angle_difference(first, second)
    (((first - second) + 180) % 360 - 180).abs
  end

  def rotation_with(instant, observer, horizontal, orientation, **options)
    view = Skymap::View.new(
      center: horizontal,
      field_of_view: Astronoby::Angle.from_degrees(2),
      orientation: orientation,
      **options
    )
    context = Skymap::Context.new(
      observer: observer,
      instant: instant,
      canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
      view: view
    )

    described_class.new(ephem: ephemeris).elements(context).first.rotation
  end
end
