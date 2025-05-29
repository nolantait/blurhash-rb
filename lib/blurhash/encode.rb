# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/ClassLength
module Blurhash
  # Encodes an image into a BlurHash string.
  class Encode
    # Error raised when the arguments to Encode.call is invalid.
    ValidationError = Class.new(Error)

    # Input data structure for the BlurHash encoding.
    Input = Data.define(:pixels, :width, :height, :component_x, :component_y) do
      # The size flag for the BlurHash string, which encodes the number of
      # components in the x and y directions.
      def size_flag
        (component_x - 1) + ((component_y - 1) * 9)
      end
    end

    # A string buffer than encodes integers into a BlurHash string.
    class Buffer
      def initialize
        @content = +""
      end

      # Adds an integer to the buffer, encoding it in Base83 format.
      # @param number [Integer] The integer to encode.
      # @param length [Integer] The length of the encoded string.
      # @return [void]
      def add(number, length)
        @content << Base83.encode(number: number, length:)
      end

      # Returns the encoded string.
      def to_s
        @content
      end
    end

    # Encodes an image into a BlurHash string.
    # (see #call)
    # @param (see #call)
    # @return (see #call)
    def self.call(...) = new.call(...)

    # @param pixels [Array<Integer>] The pixel data in sRGB format.
    # @param width [Integer] The width of the image.
    # @param height [Integer] The height of the image.
    # @param component_x [Integer] The number of components in the x
    #   direction (1-9).
    # @param component_y [Integer] The number of components in the y
    #   direction (1-9).
    # @return [String] The BlurHash string.
    def call(pixels:, width:, height:, component_x:, component_y:) # rubocop:disable Metrics/MethodLength
      input = Input
        .new(pixels:, width:, height:, component_x:, component_y:)
        .tap { validate_input(it) }

      dominant_color, additional_colors = build_factors(input)

      buffer = Buffer.new.tap do |hash|
        hash.add(input.size_flag, 1)

        if additional_colors.any?
          quant_max = additional_colors
            .map(&:max)
            .max
            .then { ((it * 166) - 0.5).floor.clamp(0, 82) }
          max_val = (quant_max + 1) / 166.0
          hash.add(quant_max, 1)
        else
          max_val = 1.0
          hash.add(0, 1)
        end

        dominant_color.tap do
          encoded_number = encode_dominant_color(it)
          hash.add(encoded_number, 4)
        end

        additional_colors.each do |factor|
          encoded_number = encode_additional_color(factor, max_val)
          hash.add(encoded_number, 2)
        end
      end

      buffer.to_s
    end

    private

    # Multiplies the basis function for each pixel and returns the
    # average color value.
    #
    # @param pixels [Array<Integer>] The pixel data in sRGB format.
    # @param width [Integer] The width of the image.
    # @param height [Integer] The height of the image.
    # @param block [Proc] A block that takes the x and y coordinates
    #   and returns the basis function value for that pixel.
    # @return [Array<Float>] The average color value in linear RGB format.
    def multiply_basis_function(pixels, width, height, &)
      r = g = b = 0.0
      bytes_per_pixel = 3
      bytes_per_row = width * bytes_per_pixel

      width.times do |x|
        base_x = bytes_per_pixel * x
        height.times do |y|
          index = base_x + (y * bytes_per_row)
          basis = yield(x, y)

          r += basis * srgb_to_linear(pixels[index])
          g += basis * srgb_to_linear(pixels[index + 1])
          b += basis * srgb_to_linear(pixels[index + 2])
        end
      end

      scale = 1.0 / (width * height)
      [r * scale, g * scale, b * scale]
    end

    # Encodes the dominant color value into a single integer.
    #
    # @param value [Array<Float>] The average color value in linear RGB format.
    # @return [Integer] The encoded DC value.
    def encode_dominant_color(value)
      r = linear_to_srgb(value[0])
      g = linear_to_srgb(value[1])
      b = linear_to_srgb(value[2])
      (r << 16) + (g << 8) + b
    end

    # Encodes the additional color value into a single integer.
    #
    # @param value [Array<Float>] The average color value in linear RGB format.
    # @param maximum_value [Float] The maximum value for the AC components.
    # @return [Integer] The encoded AC value.
    def encode_additional_color(value, maximum_value)
      quant_r = ((sign_pow(value[0] / maximum_value, 0.5) * 9) + 9.5)
        .floor
        .clamp(0, 18)
      quant_g = ((sign_pow(value[1] / maximum_value, 0.5) * 9) + 9.5)
        .floor
        .clamp(0, 18)
      quant_b = ((sign_pow(value[2] / maximum_value, 0.5) * 9) + 9.5)
        .floor
        .clamp(0, 18)

      (quant_r * 19 * 19) + (quant_g * 19) + quant_b
    end

    # Converts an sRGB value to linear RGB format.
    #
    # @param value [Integer] The sRGB value (0-255).
    # @return [Float] The linear RGB value (0.0-1.0).
    def srgb_to_linear(value)
      v = value / 255.0
      v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end

    # Converts a linear RGB value to sRGB format.
    #
    # @param value [Float] The linear RGB value (0.0-1.0).
    # @return [Integer] The sRGB value (0-255).
    def linear_to_srgb(value)
      value = value.clamp(0, 1)

      if value <= 0.0031308
        ((value * 12.92 * 255) + 0.5).truncate(0)
      else
        ((((1.055 * (value**(1.0 / 2.4))) - 0.055) * 255) + 0.5).truncate(0)
      end
    end

    # Raises the value to the specified exponent, preserving the sign.
    #
    # @param val [Float] The value to raise.
    # @param exp [Float] The exponent to raise the value to.
    # @return [Float] The signed power of the value.
    def sign_pow(val, exp)
      (val.abs**exp) * (val.negative? ? -1 : 1)
    end

    # Validates the input parameters for the BlurHash encoding.
    #
    # @param input [Input] The input data containing pixel information.
    # @raise [ValidationError] If the input parameters are invalid.
    # @return [void]
    def validate_input(input)
      if input.component_x < 1 ||
          input.component_x > 9 ||
          input.component_y < 1 ||
          input.component_y > 9
        raise ValidationError,
          "BlurHash must have between 1 and 9 components"
      end

      return if input.pixels.length == input.width * input.height * 3

      raise ValidationError,
        "Width and height must match the pixels array"
    end

    # Builds the factors for the BlurHash encoding. This method calculates
    # the average color values for the dominant and additional components.
    #
    # @param input [Input] The input data containing pixel information.
    # @return [Array<Array<Float>>] The dominant color and additional colors.
    def build_factors(input)
      factors = [].tap do |factors|
        input.component_y.times do |y|
          input.component_x.times do |x|
            normalisation = x.zero? && y.zero? ? 1 : 2
            factor = multiply_basis_function(
              input.pixels,
              input.width,
              input.height
            ) do |i, j|
              normalisation *
                Math.cos(Math::PI * x * i / input.width) *
                Math.cos(Math::PI * y * j / input.height)
            end
            factors << factor
          end
        end
      end

      [factors[0], factors[1..]]
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/ClassLength
