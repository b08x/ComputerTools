module ComputerTools
  module Commands
    class ExampleCommand < BaseCommand
      def self.description
        "An example command that generates a story based on the command line arguments."
      end

      def execute(*args)
        puts ComputerTools::Generators::ExampleGenerator.new(input: args.join(" ")).generate
      end
    end
  end
end
