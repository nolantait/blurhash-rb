# frozen_string_literal: true

RSpec.describe Blurhash::Base83 do
  describe ".encode" do
    it "encodes numbers to base83 strings" do
      result = described_class.encode(1, 5)
      expect(result).to eq("00001")

      result = described_class.encode(83, 5)
      expect(result).to eq("00010")
    end
  end

  describe ".decode" do
    it "decodes base83 strings to numbers" do
      result = described_class.decode("00001")
      expect(result).to eq(1)

      result = described_class.decode("00010")
      expect(result).to eq(83)
    end
  end
end
