module ComputerTools
  module Commands
    module ContentManagement
      class Overview < Interface::Base
      def self.description
        "Display comprehensive overview of ComputerTools features and functionality"
      end

      def execute(*args)
        format = args.first || 'console'

        output_format = case format.downcase
                        when 'markdown', 'md'
                          'markdown'
                        when 'json'
                          'json'
                        else
                          'console'
                        end

        result = ComputerTools::Generators::System::Overview.new(
          format: output_format
        ).generate

        puts result
      end
    end
    end
  end
end