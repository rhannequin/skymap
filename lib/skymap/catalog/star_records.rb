# frozen_string_literal: true

require_relative "../geometry"

module Skymap
  module Catalog
    class StarRecords
      MAGIC = "SKYS"
      VERSION = 1
      FORMAT = "L<l<s<s<s<S<s<S<"
      RECORD_SIZE = 20
      BRIGHTEST_BAND = 4
      FAINTEST_BAND = 9
      BANDS = (BRIGHTEST_BAND..FAINTEST_BAND)
      ZONE_HEIGHT = 2
      ZONES = 180 / ZONE_HEIGHT
      OFFSETS_COUNT = BANDS.size * ZONES + 1
      UNIT_SIZE = 4
      SETTINGS = [
        VERSION, BRIGHTEST_BAND, FAINTEST_BAND, ZONE_HEIGHT, RECORD_SIZE
      ].freeze
      HEADER_SIZE = MAGIC.bytesize + (SETTINGS.size + 2) * UNIT_SIZE
      NO_RECORD = 2**32 - 1
      RIGHT_ASCENSION_STEPS = 2**32
      DECLINATION_STEPS = 2**31
      MISSING = -32768
      PARALLAX_STEPS_PER_MAS = 10
      Record = Data.define(
        :right_ascension,
        :declination,
        :magnitude,
        :proper_motion_ra,
        :proper_motion_dec,
        :parallax,
        :radial_velocity,
        :hr
      )

      def self.band(magnitude)
        hundredths = (magnitude * 100).round

        (-(-hundredths).div(100)).clamp(BRIGHTEST_BAND, FAINTEST_BAND)
      end

      def self.bands_within(magnitude_limit)
        BANDS.select do |band|
          magnitude_limit.nil? || band == BRIGHTEST_BAND ||
            band - 1 < magnitude_limit
        end
      end

      def self.zone(declination)
        ((declination + 90) / ZONE_HEIGHT).floor.clamp(0, ZONES - 1)
      end

      def self.encode(stars)
        ordered = stars.sort_by do |star|
          [
            band(star.magnitude), zone(star.declination), star.right_ascension,
            star.declination, star.magnitude, star.hr || 0
          ]
        end
        counts = Hash.new(0)
        ordered.each do |star|
          counts[[band(star.magnitude), zone(star.declination)]] += 1
        end

        offsets = []
        total = 0
        BANDS.each do |band|
          ZONES.times do |zone|
            offsets << total
            total += counts[[band, zone]]
          end
        end
        offsets << total

        by_hr = []
        ordered.each_with_index { |star, index|
          by_hr[star.hr] = index if star.hr
        }
        by_hr = by_hr.map { |index| index || NO_RECORD }

        header = [MAGIC, *SETTINGS, ordered.size, by_hr.size]

        [*header, *offsets, *by_hr].pack("a4L<*") +
          ordered.map { |star| pack(star) }.join
      end

      def self.pack(star)
        [
          (star.right_ascension / 360.0 * RIGHT_ASCENSION_STEPS).round %
            RIGHT_ASCENSION_STEPS,
          (star.declination / 90.0 * DECLINATION_STEPS).round,
          (star.magnitude * 100).round,
          star.proper_motion_ra || MISSING,
          star.proper_motion_dec || MISSING,
          ((star.parallax || 0) * PARALLAX_STEPS_PER_MAS).round,
          star.radial_velocity || MISSING,
          star.hr || 0
        ].pack(FORMAT)
      end
      private_class_method :pack

      attr_reader :count

      def initialize(data)
        unless data.bytesize >= HEADER_SIZE &&
            data.byteslice(0, MAGIC.bytesize) == MAGIC
          raise ArgumentError, "data is not a star catalog"
        end

        @data = data
        settings = data.unpack("L<#{SETTINGS.size}", offset: MAGIC.bytesize)
        unless settings == SETTINGS
          raise ArgumentError, "star catalog was built with other settings"
        end

        counts_at = MAGIC.bytesize + SETTINGS.size * UNIT_SIZE
        @count, hr_count = data.unpack("L<2", offset: counts_at)
        read_tables(hr_count)
        unless @records_at + @count * RECORD_SIZE == data.bytesize
          raise ArgumentError, "star catalog has the wrong size"
        end
      end

      def each_with_hr
        return enum_for(:each_with_hr) unless block_given?

        @by_hr.each do |index|
          next if index == NO_RECORD

          yield decode(@data.unpack(FORMAT, offset: record_at(index)))
        end
      end

      def each_in_band(band)
        return enum_for(:each_in_band, band) unless block_given?

        ZONES.times do |zone|
          each_in_cell(band, zone, nil) { |record| yield record }
        end
      end

      def each(magnitude_limit: nil, center: nil, radius: nil)
        unless block_given?
          return enum_for(:each, magnitude_limit:, center:,
            radius:)
        end

        search = center && Search.new(center, radius)
        self.class.bands_within(magnitude_limit).each do |band|
          zones(search).each do |zone|
            each_in_cell(band, zone, search) do |record|
              next if magnitude_limit && record.magnitude > magnitude_limit

              yield record if search.nil? || search.include?(record)
            end
          end
        end
      end

      private

      def read_tables(hr_count)
        @offsets = @data.unpack("L<#{OFFSETS_COUNT}", offset: HEADER_SIZE)
        by_hr_at = HEADER_SIZE + OFFSETS_COUNT * UNIT_SIZE
        @by_hr = @data.unpack("L<#{hr_count}", offset: by_hr_at)
        @records_at = by_hr_at + hr_count * UNIT_SIZE
      end

      def zones(search)
        return 0...ZONES unless search

        search.zones
      end

      def each_in_cell(band, zone, search)
        first, last = cell(band, zone)
        windows = search ? search.windows : [[0, RIGHT_ASCENSION_STEPS - 1]]

        windows.each do |from, to|
          start = lower_bound(first, last, from)
          index = start
          while index < last
            raw = @data.unpack(FORMAT, offset: record_at(index))
            break if raw[0] > to

            yield decode(raw)
            index += 1
          end
        end
      end

      def cell(band, zone)
        row = (band - BRIGHTEST_BAND) * ZONES + zone

        [@offsets[row], @offsets[row + 1]]
      end

      def lower_bound(first, last, steps)
        low = first
        high = last
        while low < high
          middle = (low + high) / 2
          right_ascension = @data.unpack1("L<", offset: record_at(middle))
          if right_ascension < steps
            low = middle + 1
          else
            high = middle
          end
        end
        low
      end

      def record_at(index)
        @records_at + index * RECORD_SIZE
      end

      def decode(raw)
        right_ascension, declination, magnitude, pm_ra, pm_dec, parallax,
          radial_velocity, hr = raw

        Record.new(
          right_ascension: right_ascension * 360.0 / RIGHT_ASCENSION_STEPS,
          declination: declination * 90.0 / DECLINATION_STEPS,
          magnitude: magnitude / 100.0,
          proper_motion_ra: (pm_ra unless pm_ra == MISSING),
          proper_motion_dec: (pm_dec unless pm_dec == MISSING),
          parallax: (
            parallax.fdiv(PARALLAX_STEPS_PER_MAS) unless parallax.zero?
          ),
          radial_velocity: (radial_velocity unless radial_velocity == MISSING),
          hr: (hr unless hr.zero?)
        )
      end

      class Search
        attr_reader :center, :radius

        def initialize(center, radius)
          @center = center
          @radius = radius
          @cosine = Math.cos(radius * Math::PI / 180)
          @center_vector = vector(center.first, center.last)
        end

        def zones
          lowest = [@center.last - @radius, -90.0].max
          highest = [@center.last + @radius, 90.0].min

          StarRecords.zone(lowest)..StarRecords.zone(highest)
        end

        def windows
          width = half_width
          return [[0, RIGHT_ASCENSION_STEPS - 1]] if width >= 180

          from = @center.first - width
          to = @center.first + width
          if from.negative?
            [[0, steps(to)], [steps(from + 360), RIGHT_ASCENSION_STEPS - 1]]
          elsif to >= 360
            [[0, steps(to - 360)], [steps(from), RIGHT_ASCENSION_STEPS - 1]]
          else
            [[steps(from), steps(to)]]
          end
        end

        def include?(record)
          point = vector(record.right_ascension, record.declination)

          Geometry.dot(@center_vector, point) >= @cosine
        end

        private

        def half_width
          return 180.0 if @center.last.abs + @radius >= 90

          Math.asin(
            Math.sin(@radius * Math::PI / 180) /
            Math.cos(@center.last * Math::PI / 180)
          ) * 180 / Math::PI
        end

        def steps(degrees)
          (degrees / 360.0 * RIGHT_ASCENSION_STEPS).floor
            .clamp(0, RIGHT_ASCENSION_STEPS - 1)
        end

        def vector(right_ascension, declination)
          Geometry.direction(
            right_ascension * Math::PI / 180,
            declination * Math::PI / 180
          )
        end
      end
      private_constant :Search
    end
  end
end
