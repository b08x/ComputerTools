# frozen_string_literal: true

module ComputerTools
  module Commands
    class MenuCommand
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
        excluded_commands = %i[BaseCommand MenuCommand]
        valid_commands = ComputerTools::Commands.constants.reject do |command_class|
          excluded_commands.include?(command_class)
        end

        valid_commands.map do |command_class|
          command = ComputerTools::Commands.const_get(command_class)
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

      # Command execution helpers
      def execute_blueprint_command(subcommand, *)
        blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
        blueprint_command.execute(subcommand, *)
      end

      def execute_deepgram_command(subcommand, *)
        deepgram_command = ComputerTools::Commands::DeepgramCommand.new({})
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

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new(options)
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

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new(options)
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

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new(options)
        blueprint_command.execute('view', id)
      end

      def handle_blueprint_edit
        id = @prompt.ask("✏️ Enter blueprint ID to edit:")
        return if id.nil? || id.empty?

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
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

          blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
          blueprint_command.execute('delete', *args)
        when "interactive"
          # Use interactive selection (no ID provided)
          blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
          blueprint_command.execute('delete')
        end
      end

      def handle_blueprint_search
        query = @prompt.ask("🔍 Enter search query:")
        return if query.nil? || query.empty?

        limit = @prompt.ask("📊 Number of results (default 10):", default: "10")

        options = { 'limit' => limit.to_i }
        blueprint_command = ComputerTools::Commands::BlueprintCommand.new(options)
        blueprint_command.execute('search', query)
      end

      def handle_blueprint_export
        id = @prompt.ask("📤 Enter blueprint ID to export:")
        return if id.nil? || id.empty?

        output_path = @prompt.ask("💾 Output file path (optional):")

        args = [id]
        args << output_path unless output_path.nil? || output_path.empty?

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
        blueprint_command.execute('export', *args)
      end

      def handle_blueprint_config
        subcommand = @prompt.select("⚙️ Configuration:") do |menu|
          menu.choice "Show current config", "show"
          menu.choice "Setup configuration", "setup"
        end

        blueprint_command = ComputerTools::Commands::BlueprintCommand.new({})
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

        deepgram_command = ComputerTools::Commands::DeepgramCommand.new(options)
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

        deepgram_command = ComputerTools::Commands::DeepgramCommand.new(options)
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

        deepgram_command = ComputerTools::Commands::DeepgramCommand.new(options)
        deepgram_command.execute('convert', *args)
      end
    end
  end
end