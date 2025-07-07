# frozen_string_literal: true

module ComputerTools
  module Actions
    module Utilities
      class Example < Sublayer::Actions::Base
      def initialize(input:)
        @input = input
      end

      def call
        puts "Performing action with input: #{@input}"
      end
    end
  end
end
end