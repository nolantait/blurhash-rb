# frozen_string_literal: true

require_relative "blurhash/version"
require_relative "blurhash/base83"
require_relative "blurhash/encode"

module Blurhash
  class Error < StandardError; end
  # Your code goes here...

  def self.encode(pixels:, width:, height:, component_x: 4, component_y: 3)
    Encode.call(pixels:, width:, height:, component_x:, component_y:)
  end
end
