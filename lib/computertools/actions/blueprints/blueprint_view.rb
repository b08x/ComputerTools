# frozen_string_literal: true

module ComputerTools
  module Actions
    module Blueprints
      class BlueprintView < Sublayer::Actions::Base
      def initialize(id:, format: :detailed, with_suggestions: false)
        @id = id
        @format = format
        @with_suggestions = with_suggestions
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        puts "🔍 Fetching blueprint #{@id}...".colorize(:blue)
        
        blueprint = @db.get_blueprint(@id)
        unless blueprint
          puts "❌ Blueprint #{@id} not found".colorize(:red)
          return false
        end

        # Generate AI suggestions if requested
        if @with_suggestions
          puts "🤖 Generating AI analysis...".colorize(:yellow)
          blueprint[:ai_suggestions] = generate_suggestions(blueprint)
        end

        case @format
        when :detailed
          display_detailed(blueprint)
        when :json
          puts JSON.pretty_generate(blueprint)
        when :code_only
          puts blueprint[:code]
        when :summary
          display_summary(blueprint)
        end
        
        true
      rescue => e
        puts "❌ Error viewing blueprint: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def display_detailed(blueprint)
        content = build_detailed_content(blueprint)
        
        if tty_pager_available?
          TTY::Pager.page(content)
        else
          puts content
        end
      end

      def build_detailed_content(blueprint)
        content = []
        content << "=" * 80
        content << "📋 Blueprint Details".colorize(:blue).to_s
        content << "=" * 80
        content << "ID: #{blueprint[:id]}"
        content << "Name: #{blueprint[:name]}"
        content << "Created: #{blueprint[:created_at]}"
        content << "Updated: #{blueprint[:updated_at]}"
        content << ""
        
        # Categories
        if blueprint[:categories] && blueprint[:categories].any?
          category_names = blueprint[:categories].map { |cat| cat[:title] }
          content << "Categories: #{category_names.join(', ')}"
        else
          content << "Categories: None"
        end
        content << ""
        
        # Description
        content << "Description:"
        content << blueprint[:description] || "No description available"
        content << ""
        
        # AI Suggestions (if available)
        if blueprint[:ai_suggestions]
          content << "🤖 AI Analysis & Suggestions:".colorize(:cyan).to_s
          content << "-" * 40
          
          if blueprint[:ai_suggestions][:improvements]
            content << "💡 Improvements:".colorize(:yellow).to_s
            blueprint[:ai_suggestions][:improvements].each do |improvement|
              content << "  • #{improvement}"
            end
            content << ""
          end
          
          if blueprint[:ai_suggestions][:quality_assessment]
            content << "📊 Quality Assessment:".colorize(:yellow).to_s
            content << blueprint[:ai_suggestions][:quality_assessment]
            content << ""
          end
        end
        
        # Code
        content << "-" * 80
        content << "💻 Code:".colorize(:green).to_s
        content << "-" * 80
        content << blueprint[:code]
        content << "=" * 80
        
        content.join("\n")
      end

      def display_summary(blueprint)
        puts "\n📋 Blueprint Summary".colorize(:blue)
        puts "=" * 50
        puts "ID: #{blueprint[:id]}"
        puts "Name: #{blueprint[:name]}"
        puts "Description: #{truncate_text(blueprint[:description] || 'No description', 60)}"
        
        if blueprint[:categories] && blueprint[:categories].any?
          category_names = blueprint[:categories].map { |cat| cat[:title] }
          puts "Categories: #{category_names.join(', ')}"
        end
        
        puts "Code length: #{blueprint[:code].length} characters"
        puts "Created: #{blueprint[:created_at]}"
        puts "=" * 50
        puts ""
      end

      def generate_suggestions(blueprint)
        suggestions = {}
        
        begin
          # Generate improvement suggestions
          improvements = ComputerTools::Generators::BlueprintImprovementGenerator.new(
            code: blueprint[:code],
            description: blueprint[:description]
          ).generate
          
          suggestions[:improvements] = improvements if improvements
          
        rescue => e
          puts "⚠️  Could not generate AI suggestions: #{e.message}".colorize(:yellow)
        end
        
        suggestions
      end

      def truncate_text(text, length)
        return text if text.length <= length
        text[0..length-4] + "..."
      end

      def tty_pager_available?
        defined?(TTY::Pager)
      end
    end
  end
end
end