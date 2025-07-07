# frozen_string_literal: true

module ComputerTools
  module Commands
    module ContentManagement
      class Blueprint < Interface::Base
      def self.description
        "Manage code blueprints with AI-enhanced metadata and vector search capabilities"
      end

      def initialize(options)
        super
        @subcommand = nil
        @args = []
      end

      def execute(*args)
        @subcommand = args.shift
        @args = args

        case @subcommand
        when 'submit'
          handle_submit
        when 'list'
          handle_list
        when 'browse'
          handle_browse
        when 'view'
          handle_view
        when 'edit'
          handle_edit
        when 'delete'
          handle_delete
        when 'search'
          handle_search
        when 'export'
          handle_export
        when 'config'
          handle_config
        when 'help', nil
          show_help
        else
          puts "❌ Unknown subcommand: #{@subcommand}".colorize(:red)
          show_help
          false
        end
      end

      private

      def handle_submit
        input = @args.first

        unless input
          puts "❌ Please provide a file path or code string".colorize(:red)
          puts "Usage: blueprint submit <file_path_or_code>"
          return false
        end

        if File.exist?(input)
          puts "📁 Submitting blueprint from file: #{input}".colorize(:blue)
          code = File.read(input)
        else
          puts "📝 Submitting blueprint from code string".colorize(:blue)
          code = input
        end

        ComputerTools::Actions::BlueprintSubmit.new(
          code: code,
          auto_describe: @options['auto_describe'] != false,
          auto_categorize: @options['auto_categorize'] != false
        ).call
      end

      def handle_list
        format = (@options['format'] || 'table').to_sym
        interactive = @options['interactive'] || false

        ComputerTools::Actions::BlueprintList.new(
          format: format,
          interactive: interactive
        ).call
      end

      def handle_browse
        ComputerTools::Actions::BlueprintList.new(
          interactive: true
        ).call
      end

      def handle_view
        id = @args.first

        unless id
          puts "❌ Please provide a blueprint ID".colorize(:red)
          puts "Usage: blueprint view <id>"
          return false
        end

        format = (@options['format'] || 'detailed').to_sym

        ComputerTools::Actions::BlueprintView.new(
          id: id.to_i,
          format: format,
          with_suggestions: @options['analyze'] || false
        ).call
      end

      def handle_edit
        id = @args.first

        unless id
          puts "❌ Please provide a blueprint ID".colorize(:red)
          puts "Usage: blueprint edit <id>"
          return false
        end

        ComputerTools::Actions::BlueprintEdit.new(
          id: id.to_i
        ).call
      end

      def handle_delete
        # Check for force flag in arguments
        force = @args.include?('--force')

        # Get ID (first non-flag argument)
        id = @args.find { |arg| !arg.start_with?('--') }

        # If no ID provided, will trigger interactive selection
        ComputerTools::Actions::BlueprintDelete.new(
          id: id&.to_i,
          force: force
        ).call
      end

      def handle_search
        query = @args.join(' ')

        if query.empty?
          puts "❌ Please provide a search query".colorize(:red)
          puts "Usage: blueprint search <query>"
          return false
        end

        ComputerTools::Actions::BlueprintSearch.new(
          query: query,
          limit: @options['limit'] || 10
        ).call
      end

      def handle_export
        id = @args.first
        output_path = @args[1] || @options['output']

        unless id
          puts "❌ Please provide a blueprint ID".colorize(:red)
          puts "Usage: blueprint export <id> [output_file]"
          return false
        end

        ComputerTools::Actions::BlueprintExport.new(
          id: id.to_i,
          output_path: output_path
        ).call
      end

      def handle_config
        subcommand = @args.first || 'show'

        ComputerTools::Actions::BlueprintConfig.new(
          subcommand: subcommand
        ).call
      end

      def show_help
        puts <<~HELP
          Blueprint Management Commands:

          📝 Content Management:
            blueprint submit <file_or_code>     Submit a new blueprint
            blueprint edit <id>                 Edit existing blueprint (delete + resubmit)
            blueprint delete [id]               Delete blueprint (interactive if no ID)
            blueprint export <id> [file]        Export blueprint code to file

          📋 Browsing & Search:
            blueprint list                      List all blueprints
            blueprint browse                    Interactive blueprint browser
            blueprint view <id>                 View specific blueprint
            blueprint search <query>            Search blueprints by content

          🔧 Configuration:
            blueprint config [show|setup]      Manage configuration

          Options:
            --format FORMAT                     Output format (table, json, summary, detailed)
            --interactive                       Interactive mode with prompts
            --output FILE                       Output file path
            --analyze                          Include AI analysis and suggestions
            --force                            Skip confirmation prompts (use with caution)
            --auto_describe=false              Disable auto-description generation
            --auto_categorize=false            Disable auto-categorization

          Examples:
            blueprint submit my_code.rb
            blueprint submit 'puts "hello world"'
            blueprint list --format summary
            blueprint browse
            blueprint view 123 --analyze
            blueprint edit 123
            blueprint delete 123
            blueprint delete --force 123
            blueprint delete                        # Interactive selection
            blueprint search "ruby class"
            blueprint export 123 my_blueprint.rb

        HELP
      end
    end
    end
  end
end