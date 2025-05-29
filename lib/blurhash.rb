# frozen_string_literal: true

require_relative "blurhash/version"
require_relative "blurhash/error"
require_relative "blurhash/base83"
require_relative "blurhash/encode"

module Blurhash
  # Encodes an image into a BlurHash string.
  #
  # @param (see Encode.call)
  # @return (see Encode.call)
  def self.encode(pixels:, width:, height:, component_x: 4, component_y: 3)
    Encode.call(pixels:, width:, height:, component_x:, component_y:)
  end
end
