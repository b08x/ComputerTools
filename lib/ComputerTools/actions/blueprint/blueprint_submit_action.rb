# frozen_string_literal: true

module ComputerTools
  module Actions
    class BlueprintSubmitAction < Sublayer::Actions::Base
      def initialize(code:, name: nil, description: nil, categories: nil, auto_describe: true, auto_categorize: true)
        @code = code
        @name = name
        @description = description
        @categories = categories || []
        @auto_describe = auto_describe
        @auto_categorize = auto_categorize
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        puts "🚀 Processing blueprint submission...".colorize(:blue)
        
        # Generate missing metadata using AI
        generate_missing_metadata
        
        # Validate required fields
        unless validate_blueprint_data
          return false
        end

        # Create the blueprint in database
        blueprint = @db.create_blueprint(
          code: @code,
          name: @name,
          description: @description,
          categories: @categories
        )

        if blueprint
          puts "✅ Blueprint created successfully!".colorize(:green)
          display_blueprint_summary(blueprint)
          true
        else
          puts "❌ Failed to create blueprint".colorize(:red)
          false
        end
      rescue => e
        puts "❌ Error submitting blueprint: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def generate_missing_metadata
        # Generate name if not provided
        if @name.nil? || @name.strip.empty?
          puts "📝 Generating blueprint name...".colorize(:yellow)
          @name = ComputerTools::Generators::BlueprintNameGenerator.new(
            code: @code,
            description: @description
          ).generate
          puts "   Generated name: #{@name}".colorize(:cyan)
        end

        # Generate description if not provided and auto_describe is enabled
        if (@description.nil? || @description.strip.empty?) && @auto_describe
          puts "📖 Generating blueprint description...".colorize(:yellow)
          @description = ComputerTools::Generators::BlueprintDescriptionGenerator.new(
            code: @code
          ).generate
          puts "   Generated description: #{truncate_text(@description, 80)}".colorize(:cyan)
        end

        # Generate categories if not provided and auto_categorize is enabled
        if @categories.empty? && @auto_categorize
          puts "🏷️  Generating blueprint categories...".colorize(:yellow)
          @categories = ComputerTools::Generators::BlueprintCategoryGenerator.new(
            code: @code,
            description: @description
          ).generate
          puts "   Generated categories: #{@categories.join(', ')}".colorize(:cyan)
        end
      end

      def validate_blueprint_data
        errors = []

        if @code.nil? || @code.strip.empty?
          errors << "Code cannot be empty"
        end

        if @name.nil? || @name.strip.empty?
          errors << "Name is required (auto-generation failed)"
        end

        if @description.nil? || @description.strip.empty?
          if @auto_describe
            errors << "Description generation failed"
          else
            puts "⚠️  Warning: No description provided".colorize(:yellow)
          end
        end

        if errors.any?
          puts "❌ Validation errors:".colorize(:red)
          errors.each { |error| puts "   - #{error}".colorize(:red) }
          return false
        end

        true
      end

      def display_blueprint_summary(blueprint)
        puts "\n" + "=" * 60
        puts "📋 Blueprint Summary".colorize(:blue)
        puts "=" * 60
        puts "ID: #{blueprint[:id]}"
        puts "Name: #{blueprint[:name]}"
        puts "Description: #{blueprint[:description]}"
        
        if blueprint[:categories] && blueprint[:categories].any?
          category_names = blueprint[:categories].map { |cat| cat[:title] }
          puts "Categories: #{category_names.join(', ')}"
        end
        
        puts "Code length: #{@code.length} characters"
        puts "Created: #{blueprint[:created_at]}"
        puts "=" * 60
        puts ""
      end

      def truncate_text(text, length)
        return text if text.length <= length
        text[0..length-4] + "..."
      end
    end
  end
end