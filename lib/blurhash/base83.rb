# frozen_string_literal: true

module Blurhash
  module Base83
    DIGIT_CHARACTERS =
      # rubocop:disable Layout/MultilineArrayLineBreaks
      %w(
        0 1 2 3 4 5 6 7 8 9
        A B C D E F G H I J
        K L M N O P Q R S T
        U V W X Y Z a b c d
        e f g h i j k l m n
        o p q r s t u v w x
        y z # $ % * + , - .
        : ; = ? @ [ ] ^ _ {
        | } ~
      ).freeze
    # rubocop:enable Layout/MultilineArrayLineBreaks

    def self.encode(number, length)
      result = ""

      (1..length).each do |integer|
        digit = (number.floor / (83**(length - integer))) % 83
        result += DIGIT_CHARACTERS[digit.floor]
      end

      result
    end

    def self.decode(string)
      value = 0

      string.each_char.with_index do |char, index|
        digit = DIGIT_CHARACTERS.index(char)
        value = (value * 83) + digit
      end

      value
    end
  end
end
