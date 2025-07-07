# frozen_string_literal: true
require 'tty-prompt'
module ComputerTools
  module Commands
    module Interface
      class Menu
      def initialize(debug: false)
        @prompt = TTY::Prompt.new
        @commands = available_commands
        @debug = debug
      end

      def start
        loop do
          choice = main_menu

          # Debug logging
          debug_log("Choice selected: #{choice.inspect} (#{choice.class})")

          case choice
          when :exit
            puts "👋 Goodbye!".colorize(:green)
            break
          else
            # All command names are strings, so handle them directly
            debug_log("Handling command: #{choice}")
            result = handle_command(choice)
            debug_log("Command result: #{result}")
            # If command handler returns :exit, break the loop
            break if result == :exit
          end
        end
      end

      private

      def debug_log(message)
        puts "🔍 DEBUG: #{message}".colorize(:magenta) if @debug
      end

      def available_commands
        excluded_commands = %i[Base Menu]
        commands = []
        
        # Search through all nested modules in Commands (same logic as CLI)
        ComputerTools::Commands.constants.each do |module_name|
          module_obj = ComputerTools::Commands.const_get(module_name)
          if module_obj.is_a?(Module)
            module_obj.constants.each do |class_name|
              command_class = ComputerTools::Commands.const_get(module_name).const_get(class_name)
              # Only include classes that respond to command_name and are not excluded
              if command_class.respond_to?(:command_name) && !excluded_commands.include?(command_class.name.split('::').last.to_sym)
                commands << command_class
              end
            end
          end
        end
        
        commands.map do |command|
          {
            name: command.command_name,
            description: command.description,
            class: command
          }
        end
      end

      def main_menu
        debug_log("Building main menu with commands: #{@commands.map { |cmd| cmd[:name] }}")

        result = @prompt.select("🚀 ComputerTools - Select a command:".colorize(:cyan)) do |menu|
          @commands.each do |cmd|
            debug_log("Adding menu choice: '#{cmd[:name].capitalize} - #{cmd[:description]}' -> #{cmd[:name].inspect}")
            menu.choice "#{cmd[:name].capitalize} - #{cmd[:description]}", cmd[:name]
          end
          menu.choice "Exit", :exit
        end

        debug_log("Menu selection returned: #{result.inspect}")
        result
      end

      def handle_command(command_name)
        debug_log("Looking for command: #{command_name.inspect}")
        debug_log("Available commands: #{@commands.map { |cmd| cmd[:name] }}")

        command_info = @commands.find { |cmd| cmd[:name] == command_name }
        debug_log("Command found: #{command_info ? 'YES' : 'NO'}")

        return :continue unless command_info

        debug_log("Executing command handler for: #{command_name}")
        case command_name
        when 'blueprint'
          handle_blueprint_command
        when 'deepgram'
          handle_deepgram_command
        when 'example'
          handle_example_command
        when 'latestchanges'
          handle_latest_changes_command
        when 'overview'
          handle_overview_command
        else
          puts "❌ Unknown command: #{command_name}".colorize(:red)
          :continue
        end
      end

      def handle_blueprint_command
        debug_log("Entering handle_blueprint_command")
        subcommand = @prompt.select("📋 Blueprint - Choose operation:".colorize(:blue)) do |menu|
          menu.choice "Submit new blueprint", "submit"
          menu.choice "List all blueprints", "list"
          menu.choice "Browse blueprints interactively", "browse"
          menu.choice "View specific blueprint", "view"
          menu.choice "Edit blueprint", "edit"
          menu.choice "Delete blueprint", "delete"
          menu.choice "Search blueprints", "search"
          menu.choice "Export blueprint", "export"
          menu.choice "Configuration", "config"
          menu.choice "Back to main menu", :back
        end

        return :continue if subcommand == :back

        begin
          case subcommand
          when "submit"
            handle_blueprint_submit
          when "list"
            handle_blueprint_list
          when "browse"
            execute_blueprint_command("browse")
          when "view"
            handle_blueprint_view
          when "edit"
            handle_blueprint_edit
          when "delete"
            handle_blueprint_delete
          when "search"
            handle_blueprint_search
          when "export"
            handle_blueprint_export
          when "config"
            handle_blueprint_config
          end
        rescue StandardError => e
          puts "❌ Error executing blueprint command: #{e.message}".colorize(:red)
        end

        :continue
      end

      def handle_deepgram_command
        debug_log("Entering handle_deepgram_command")
        subcommand = @prompt.select("🎙️ Deepgram - Choose operation:".colorize(:blue)) do |menu|
          menu.choice "Parse JSON output", "parse"
          menu.choice "Analyze with AI insights", "analyze"
          menu.choice "Convert to different format", "convert"
          menu.choice "Configuration", "config"
          menu.choice "Back to main menu", :back
        end

        return :continue if subcommand == :back

        begin
          case subcommand
          when "parse"
            handle_deepgram_parse
          when "analyze"
            handle_deepgram_analyze
          when "convert"
            handle_deepgram_convert
          when "config"
            execute_deepgram_command("config")
          end
        rescue StandardError => e
          puts "❌ Error executing deepgram command: #{e.message}".colorize(:red)
        end

        :continue
      end

      def handle_example_command
        debug_log("Entering handle_example_command")
        puts "🎯 Running example command...".colorize(:green)
        begin
          # Create a simple example instead of using the potentially problematic generator
          example_text = "This is a simple example story: Once upon a time, ComputerTools was created to help " \
                         "developers manage their code blueprints and process Deepgram audio transcriptions. The end!"
          puts example_text.colorize(:yellow)

          # Pause to let user read the output
          @prompt.keypress("Press any key to continue...")
        rescue StandardError => e
          puts "❌ Error running example: #{e.message}".colorize(:red)
        end
        :continue
      end

      def handle_latest_changes_command
        debug_log("Entering handle_latest_changes_command")
        
        subcommand = @prompt.select("📊 Latest Changes - Choose operation:".colorize(:blue)) do |menu|
          menu.choice "Analyze recent changes", "analyze"
          menu.choice "Configure settings", "config"
          menu.choice "Help", "help"
          menu.choice "Back to main menu", :back
        end

        return :continue if subcommand == :back

        case subcommand
        when "analyze"
          handle_latest_changes_analyze
        when "config"
          handle_latest_changes_config
        when "help"
          handle_latest_changes_help
        end
        :continue
      end

      # Command execution helpers
      def execute_blueprint_command(subcommand, *)
        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
        blueprint_command.execute(subcommand, *)
      end

      def execute_deepgram_command(subcommand, *)
        deepgram_command = ComputerTools::Commands::MediaProcessing::Deepgram.new({})
        deepgram_command.execute(subcommand, *)
      end

      # Blueprint subcommand handlers
      def handle_blueprint_submit
        input = @prompt.ask("📁 Enter file path or code string:")
        return if input.nil? || input.empty?

        auto_describe = @prompt.yes?("🤖 Auto-generate description?")
        auto_categorize = @prompt.yes?("🏷️ Auto-categorize?")

        args = [input]
        options = {}
        options['auto_describe'] = false unless auto_describe
        options['auto_categorize'] = false unless auto_categorize

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new(options)
        blueprint_command.execute('submit', *args)
      end

      def handle_blueprint_list
        format = @prompt.select("📊 Choose format:") do |menu|
          menu.choice "Table", "table"
          menu.choice "Summary", "summary"
          menu.choice "JSON", "json"
        end

        interactive = @prompt.yes?("🔄 Interactive mode?")

        options = { 'format' => format }
        options['interactive'] = true if interactive

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new(options)
        blueprint_command.execute('list')
      end

      def handle_blueprint_view
        id = @prompt.ask("🔍 Enter blueprint ID:")
        return if id.nil? || id.empty?

        format = @prompt.select("📊 Choose format:") do |menu|
          menu.choice "Detailed", "detailed"
          menu.choice "Summary", "summary"
          menu.choice "JSON", "json"
        end

        analyze = @prompt.yes?("🧠 Include AI analysis?")

        options = { 'format' => format }
        options['analyze'] = true if analyze

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new(options)
        blueprint_command.execute('view', id)
      end

      def handle_blueprint_edit
        id = @prompt.ask("✏️ Enter blueprint ID to edit:")
        return if id.nil? || id.empty?

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
        blueprint_command.execute('edit', id)
      end

      def handle_blueprint_delete
        # Give user options: enter ID or select interactively
        choice = @prompt.select("🗑️ How would you like to select the blueprint to delete?") do |menu|
          menu.choice "Enter blueprint ID", "id"
          menu.choice "Select from list", "interactive"
        end

        case choice
        when "id"
          id = @prompt.ask("🗑️ Enter blueprint ID to delete:")
          return if id.nil? || id.empty?

          # Ask about force deletion
          force = @prompt.yes?("⚠️ Skip confirmation? (Use with caution)")

          args = [id]
          args << "--force" if force

          blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
          blueprint_command.execute('delete', *args)
        when "interactive"
          # Use interactive selection (no ID provided)
          blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
          blueprint_command.execute('delete')
        end
      end

      def handle_blueprint_search
        query = @prompt.ask("🔍 Enter search query:")
        return if query.nil? || query.empty?

        limit = @prompt.ask("📊 Number of results (default 10):", default: "10")

        options = { 'limit' => limit.to_i }
        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new(options)
        blueprint_command.execute('search', query)
      end

      def handle_blueprint_export
        id = @prompt.ask("📤 Enter blueprint ID to export:")
        return if id.nil? || id.empty?

        output_path = @prompt.ask("💾 Output file path (optional):")

        args = [id]
        args << output_path unless output_path.nil? || output_path.empty?

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
        blueprint_command.execute('export', *args)
      end

      def handle_blueprint_config
        subcommand = @prompt.select("⚙️ Configuration:") do |menu|
          menu.choice "Show current config", "show"
          menu.choice "Setup configuration", "setup"
        end

        blueprint_command = ComputerTools::Commands::ContentManagement::Blueprint.new({})
        blueprint_command.execute('config', subcommand)
      end

      # Deepgram subcommand handlers
      def handle_deepgram_parse
        json_file = @prompt.ask("📁 Enter JSON file path:")
        return if json_file.nil? || json_file.empty?

        format = @prompt.select("📊 Choose output format:") do |menu|
          menu.choice "Markdown", "markdown"
          menu.choice "SRT", "srt"
          menu.choice "JSON", "json"
          menu.choice "Summary", "summary"
        end

        console_output = @prompt.yes?("🖥️ Display in console?")
        output_file = @prompt.ask("💾 Output file path (optional):")

        args = [json_file, format]
        options = {}
        options['console'] = true if console_output
        options['output'] = output_file unless output_file.nil? || output_file.empty?

        deepgram_command = ComputerTools::Commands::MediaProcessing::Deepgram.new(options)
        deepgram_command.execute('parse', *args)
      end

      def handle_deepgram_analyze
        json_file = @prompt.ask("📁 Enter JSON file path:")
        return if json_file.nil? || json_file.empty?

        interactive = @prompt.yes?("🔄 Interactive mode?")
        console_output = @prompt.yes?("🖥️ Display in console?")

        options = {}
        options['interactive'] = true if interactive
        options['console'] = true if console_output

        deepgram_command = ComputerTools::Commands::MediaProcessing::Deepgram.new(options)
        deepgram_command.execute('analyze', json_file)
      end

      def handle_deepgram_convert
        json_file = @prompt.ask("📁 Enter JSON file path:")
        return if json_file.nil? || json_file.empty?

        format = @prompt.select("📊 Choose target format:") do |menu|
          menu.choice "Markdown", "markdown"
          menu.choice "SRT", "srt"
          menu.choice "JSON", "json"
          menu.choice "Summary", "summary"
        end

        console_output = @prompt.yes?("🖥️ Display in console?")
        output_file = @prompt.ask("💾 Output file path (optional):")

        args = [json_file, format]
        options = {}
        options['console'] = true if console_output
        options['output'] = output_file unless output_file.nil? || output_file.empty?

        deepgram_command = ComputerTools::Commands::MediaProcessing::Deepgram.new(options)
        deepgram_command.execute('convert', *args)
      end

      # Latest Changes subcommand handlers
      def handle_latest_changes_analyze
        directory = @prompt.ask("📁 Directory to analyze (default: current):", default: ".")
        
        time_range = @prompt.select("⏰ Time range:") do |menu|
          menu.choice "Last hour", "1h"
          menu.choice "Last 6 hours", "6h"
          menu.choice "Last 24 hours", "24h"
          menu.choice "Last 2 days", "2d"
          menu.choice "Last week", "7d"
          menu.choice "Custom", "custom"
        end

        if time_range == "custom"
          time_range = @prompt.ask("Enter custom time range (e.g., 3h, 5d, 2w):")
        end

        format = @prompt.select("📊 Output format:") do |menu|
          menu.choice "Table", "table"
          menu.choice "Summary", "summary"
          menu.choice "JSON", "json"
        end

        interactive = @prompt.yes?("🔄 Interactive mode?")

        options = {
          'directory' => directory,
          'time_range' => time_range,
          'format' => format
        }
        options['interactive'] = true if interactive

        latest_changes_command = ComputerTools::Commands::Analysis::LatestChanges.new(options)
        latest_changes_command.execute('analyze')
      end

      def handle_latest_changes_config
        latest_changes_command = ComputerTools::Commands::Analysis::LatestChanges.new({})
        latest_changes_command.execute('config')
      end

      def handle_latest_changes_help
        latest_changes_command = ComputerTools::Commands::Analysis::LatestChanges.new({})
        latest_changes_command.execute('help')
      end

      def handle_overview_command
        debug_log("Entering handle_overview_command")
        
        format = @prompt.select("📊 Choose output format:") do |menu|
          menu.choice "Console (colored)", "console"
          menu.choice "Markdown", "markdown"
          menu.choice "JSON", "json"
        end

        begin
          overview_command = ComputerTools::Commands::ContentManagement::Overview.new({})
          overview_command.execute(format)
        rescue StandardError => e
          puts "❌ Error executing overview command: #{e.message}".colorize(:red)
        end

        :continue
      end
    end
    end
  end
end