# frozen_string_literal: true

require "rexml/document"

module SVGHelpers
  def circles_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/circle")
  end

  def lines_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/line")
  end

  def texts_in(svg)
    REXML::XPath.match(REXML::Document.new(svg), "/svg/text")
  end
end

RSpec.configure do |config|
  config.include SVGHelpers
end
