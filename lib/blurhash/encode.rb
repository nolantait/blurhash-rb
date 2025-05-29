# frozen_string_literal: true

module Blurhash
  class Encode
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def self.call(...) = new.call(...)

    def call(pixels:, width:, height:, component_x:, component_y:)
      if component_x < 1 ||
          component_x > 9 ||
          component_y < 1 ||
          component_y > 9
        raise ValidationError,
          "BlurHash must have between 1 and 9 components"
      end
      unless pixels.length == width * height * 4
        raise ValidationError,
          "Width and height must match the pixels array"
      end

      factors = []

      component_y.times do |y|
        component_x.times do |x|
          normalisation = x.zero? && y.zero? ? 1 : 2
          factor = multiply_basis_function(pixels, width, height) do |i, j|
            normalisation *
              Math.cos(Math::PI * x * i / width) *
              Math.cos(Math::PI * y * j / height)
          end
          factors << factor
        end
      end

      dc = factors[0]
      ac = factors[1..]

      hash = +""

      size_flag = (component_x - 1) + ((component_y - 1) * 9)
      hash << Base83.encode(size_flag, 1)

      if ac.any?
        actual_max = ac
          .map(&:max)
          .max
        quant_max = ((actual_max * 166) - 0.5).floor.clamp(0, 82)
        max_val = (quant_max + 1) / 166.0
        hash << Base83.encode(quant_max, 1)
      else
        max_val = 1.0
        hash << Base83.encode(0, 1)
      end

      hash << Base83.encode(encode_dc(dc), 4)

      ac.each do |factor|
        hash << Base83.encode(encode_ac(factor, max_val), 2)
      end

      hash
    end

    private

    def multiply_basis_function(pixels, width, height, &)
      r = g = b = 0.0
      bytes_per_pixel = 4
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

    def encode_dc(value)
      r = linear_to_srgb(value[0])
      g = linear_to_srgb(value[1])
      b = linear_to_srgb(value[2])
      (r << 16) + (g << 8) + b
    end

    def encode_ac(value, maximum_value)
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

    def srgb_to_linear(value)
      v = value / 255.0
      v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end

    def linear_to_srgb(value)
      v = if value <= 0.0031308
        value * 12.92
      else
        (1.055 * (value**(1.0 / 2.4))) - 0.055
      end

      [((v * 255) + 0.5).floor, 0].max.clamp(0, 255)
    end

    def sign_pow(val, exp)
      (val.abs**exp) * (val.negative? ? -1 : 1)
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
