# frozen_string_literal: true

module ComputerTools
  module Actions
    class ExampleAction < ComputerTools::Actions::BaseAction
      def initialize(input:)
        @input = input
      end

      def call
        puts "Performing action with input: #{@input}"
      end
    end
  end
end
