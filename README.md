# Blurhash

This is a pure ruby implementation of the [blurhash](https://blurha.sh/)
algorithm.

There are other Ruby based libraries for this. But all of them use compiled
dependencies which tend to cause issues over time.

Currently it only handles encoding.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash bundle add blurhash-rb ```

If bundler is not being used to manage dependencies, install the gem by
executing:

```bash gem install blurhash-rb ```

## Usage

To use it you just need to feed in the `pixels`, `width` and `height` of the
image.

```ruby
require "blurhash-rb"

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
      a = ChunkyPNG::Color.a(pixel)
      pixels.push(r, g, b, a)
    end
  end

  [pixels, width, height]
end

pixels, width, height = load_image_as_rgba("spec/fixtures/test.png")

hash = described_class.call(
  pixels:,
  width:,
  height:,
  component_x: 4,
  component_y: 3
)

puts hash #=> "LEHV6nae2yk8pyo0adR*.7kCMdnj"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/nolantait/blurhash-rb.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
