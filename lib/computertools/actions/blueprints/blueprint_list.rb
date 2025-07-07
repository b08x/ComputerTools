# frozen_string_literal: true

module ComputerTools
  module Actions
    module Blueprints
      class BlueprintList < Sublayer::Actions::Base
      def initialize(format: :table, interactive: false, limit: 50)
        @format = format
        @interactive = interactive
        @limit = limit
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        puts "📋 Fetching blueprints...".colorize(:blue)
        
        blueprints = @db.list_blueprints(limit: @limit)
        
        if blueprints.empty?
          puts "📭 No blueprints found".colorize(:yellow)
          return true
        end

        puts "✅ Found #{blueprints.length} blueprints".colorize(:green)
        
        if @interactive && tty_prompt_available?
          interactive_blueprint_browser(blueprints)
        else
          display_blueprints(blueprints)
        end
        
        true
      rescue => e
        puts "❌ Error listing blueprints: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def display_blueprints(blueprints)
        case @format
        when :table
          display_table(blueprints)
        when :summary
          display_summary(blueprints)
        when :json
          puts JSON.pretty_generate(blueprints)
        else
          display_table(blueprints)
        end
      end

      def display_table(blueprints)
        puts "\n" + "=" * 120
        printf "%-5s %-30s %-50s %-25s\n", "ID", "Name", "Description", "Categories"
        puts "=" * 120
        
        blueprints.each do |blueprint|
          name = truncate_text(blueprint[:name] || 'Untitled', 28)
          description = truncate_text(blueprint[:description] || 'No description', 48)
          categories = get_category_text(blueprint[:categories])
          
          printf "%-5s %-30s %-50s %-25s\n", 
                 blueprint[:id], 
                 name, 
                 description, 
                 categories
        end
        puts "=" * 120
        puts ""
      end

      def display_summary(blueprints)
        puts "\n📊 Blueprint Collection Summary".colorize(:blue)
        puts "=" * 50
        puts "Total blueprints: #{blueprints.length}"
        
        # Category analysis
        all_categories = blueprints.flat_map { |b| b[:categories].map { |c| c[:name] } }
        category_counts = all_categories.each_with_object(Hash.new(0)) { |cat, hash| hash[cat] += 1 }
        
        if category_counts.any?
          puts "\nTop categories:"
          category_counts.sort_by { |_, count| -count }.first(5).each do |category, count|
            puts "  #{category}: #{count} blueprints"
          end
        end
        
        # Recent blueprints
        puts "\nMost recent blueprints:"
        blueprints.first(5).each do |blueprint|
          puts "  #{blueprint[:id]}: #{blueprint[:name]}"
        end
        puts ""
      end

      def interactive_blueprint_browser(blueprints)
        return unless tty_prompt_available?
        
        prompt = TTY::Prompt.new
        
        loop do
          puts "\n" + "=" * 80
          puts "📚 Blueprint Browser".colorize(:blue)
          puts "Found #{blueprints.length} blueprints"
          puts "=" * 80
          
          # Prepare choices for the prompt
          choices = prepare_blueprint_choices(blueprints)
          
          # Add action options
          choices << { name: "🔍 Search blueprints".colorize(:blue), value: :search }
          choices << { name: "📊 Show summary".colorize(:yellow), value: :summary }
          choices << { name: "➕ Submit new blueprint".colorize(:green), value: :submit }
          choices << { name: "🚪 Exit".colorize(:red), value: :exit }
          
          selected = prompt.select("Select a blueprint or action:", choices, per_page: 15)
          
          case selected
          when Hash
            # A blueprint was selected
            handle_selected_blueprint(selected, prompt)
          when :search
            handle_search_action(prompt)
          when :summary
            display_summary(blueprints)
            prompt.keypress("Press any key to continue...")
          when :submit
            handle_submit_action(prompt)
          when :exit
            puts "👋 Goodbye!".colorize(:green)
            break
          end
        end
      end

      def prepare_blueprint_choices(blueprints)
        blueprints.map do |blueprint|
          name = truncate_text(blueprint[:name] || 'Untitled', 40)
          description = truncate_text(blueprint[:description] || 'No description', 50)
          categories = get_category_text(blueprint[:categories], 20)
          
          display_text = "#{name.ljust(42)} | #{description.ljust(52)} | #{categories}"
          
          {
            name: display_text,
            value: blueprint
          }
        end
      end

      def handle_selected_blueprint(blueprint, prompt)
        actions = [
          { name: "👁️  View details", value: :view },
          { name: "✏️  Edit blueprint", value: :edit },
          { name: "💾 Export code", value: :export },
          { name: "🔍 View with AI analysis", value: :analyze },
          { name: "📋 Copy ID", value: :copy_id },
          { name: "↩️  Back to list", value: :back }
        ]
        
        action = prompt.select("What would you like to do with '#{blueprint[:name]}'?", actions)
        
        case action
        when :view
          ComputerTools::Actions::BlueprintView.new(
            id: blueprint[:id],
            format: :detailed
          ).call
          prompt.keypress("Press any key to continue...")
        when :edit
          ComputerTools::Actions::BlueprintEdit.new(
            id: blueprint[:id]
          ).call
          prompt.keypress("Press any key to continue...")
        when :export
          filename = prompt.ask("💾 Export filename:", default: generate_export_filename(blueprint))
          ComputerTools::Actions::BlueprintExport.new(
            id: blueprint[:id],
            output_path: filename
          ).call
          prompt.keypress("Press any key to continue...")
        when :analyze
          ComputerTools::Actions::BlueprintView.new(
            id: blueprint[:id],
            format: :detailed,
            with_suggestions: true
          ).call
          prompt.keypress("Press any key to continue...")
        when :copy_id
          puts "📋 Blueprint ID: #{blueprint[:id]}".colorize(:green)
          # Try to copy to clipboard if available
          copy_to_clipboard(blueprint[:id].to_s)
          prompt.keypress("Press any key to continue...")
        when :back
          # Return to blueprint list
          return
        end
      end

      def handle_search_action(prompt)
        query = prompt.ask("🔍 Enter search query:", required: true)
        
        ComputerTools::Actions::BlueprintSearch.new(
          query: query,
          limit: 10
        ).call
        
        prompt.keypress("Press any key to continue...")
      end

      def handle_submit_action(prompt)
        submit_choice = prompt.select("Submit from:", [
          { name: "📁 File", value: :file },
          { name: "✏️  Text input", value: :text }
        ])
        
        if submit_choice == :file
          file_path = prompt.ask("📁 Enter file path:")
          if file_path && File.exist?(file_path)
            code = File.read(file_path)
            ComputerTools::Actions::BlueprintSubmit.new(code: code).call
          else
            puts "❌ File not found: #{file_path}".colorize(:red)
          end
        else
          code = prompt.multiline("✏️  Enter code (Ctrl+D to finish):")
          if code && !code.join("\n").strip.empty?
            ComputerTools::Actions::BlueprintSubmit.new(code: code.join("\n")).call
          end
        end
        
        prompt.keypress("Press any key to continue...")
      end

      def get_category_text(categories, max_length = 23)
        return 'No categories' if categories.nil? || categories.empty?
        
        category_names = categories.map { |cat| cat[:title] }
        text = category_names.join(', ')
        truncate_text(text, max_length)
      end

      def generate_export_filename(blueprint)
        base_name = (blueprint[:name] || 'blueprint').gsub(/[^a-zA-Z0-9_-]/, '_').downcase
        extension = detect_file_extension(blueprint[:code] || '')
        "#{base_name}_#{blueprint[:id]}#{extension}"
      end

      def detect_file_extension(code)
        case code
        when /class\s+\w+.*<.*ApplicationRecord/m, /def\s+\w+.*end/m
          '.rb'
        when /function\s+\w+\s*\(/m, /const\s+\w+\s*=/m
          '.js'
        when /def\s+\w+\s*\(/m, /import\s+\w+/m
          '.py'
        when /#include\s*<.*>/m, /int\s+main\s*\(/m
          '.c'
        else
          '.txt'
        end
      end

      def copy_to_clipboard(text)
        # Try different clipboard commands
        commands = [
          "echo '#{text}' | pbcopy",           # macOS
          "echo '#{text}' | xclip -selection clipboard", # Linux with xclip
          "echo '#{text}' | xsel -i -b"       # Linux with xsel
        ]
        
        commands.each do |cmd|
          if system(cmd + " 2>/dev/null")
            puts "📋 Copied to clipboard!".colorize(:green)
            return true
          end
        end
        
        puts "⚠️  Could not copy to clipboard (clipboard tool not available)".colorize(:yellow)
        false
      end

      def truncate_text(text, length)
        return text if text.length <= length
        text[0..length-4] + "..."
      end

      def tty_prompt_available?
        defined?(TTY::Prompt)
      end
    end
  end
end
end