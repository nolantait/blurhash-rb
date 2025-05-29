# frozen_string_literal: true

require "chunky_png"

RSpec.describe Blurhash::Encode do
  def load_image_as_rgba(path)
    image = ChunkyPNG::Image.from_file(path)
    width = image.width
    height = image.height
    pixels = []

    height.times do |y|
      width.times do |x|
        pixel = image[x, y]
        r = ChunkyPNG::Color.r(pixel)
        g = ChunkyPNG::Color.g(pixel)
        b = ChunkyPNG::Color.b(pixel)
        pixels.push(r, g, b)
      end
    end

    [pixels, width, height]
  end

  describe ".call" do
    it "encodes an image" do
      pixels, width, height = load_image_as_rgba("spec/fixtures/test.png")
      hash = described_class.call(
        pixels:,
        width:,
        height:,
        component_x: 4,
        component_y: 3
      )

      expect(hash).to eq("LEHV6nae2yk8pyo0adR*.7kCMdnj")
    end
  end
end
