# frozen_string_literal: true

require "rexml/document"

module SVGHelpers
  def circles_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/circle")
  end

  def lines_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/line")
  end

  def groups_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/g")
  end

  def polylines_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/polyline")
  end

  def texts_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/text")
  end
end

RSpec.configure do |config|
  config.include SVGHelpers
end
