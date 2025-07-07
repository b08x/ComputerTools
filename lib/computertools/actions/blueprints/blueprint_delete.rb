# frozen_string_literal: true

module ComputerTools
  module Actions
    module Blueprints
      class BlueprintDelete < Sublayer::Actions::Base
      def initialize(id: nil, force: false)
        @id = id
        @force = force
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        # If no ID provided, show interactive selection
        if @id.nil?
          @id = select_blueprint_interactively
          return false unless @id
        end

        # Fetch the blueprint to delete
        blueprint = @db.get_blueprint(@id)
        unless blueprint
          puts "❌ Blueprint #{@id} not found".colorize(:red)
          return false
        end

        # Show blueprint details and confirm deletion
        return false if !@force && !confirm_deletion?(blueprint)

        # Perform the deletion
        puts "🗑️  Deleting blueprint...".colorize(:yellow)

        if @db.delete_blueprint(@id)
          puts "✅ Blueprint '#{blueprint[:name]}' (ID: #{@id}) deleted successfully".colorize(:green)
          true
        else
          puts "❌ Failed to delete blueprint".colorize(:red)
          false
        end
      rescue StandardError => e
        puts "❌ Error deleting blueprint: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def select_blueprint_interactively
        puts "🔍 Loading blueprints for selection...".colorize(:blue)

        blueprints = @db.list_blueprints(limit: 50)

        if blueprints.empty?
          puts "❌ No blueprints found".colorize(:red)
          return nil
        end

        puts "\nSelect a blueprint to delete:"
        puts "=" * 60

        blueprints.each_with_index do |blueprint, index|
          categories = blueprint[:categories].map { |c| c[:title] }.join(', ')
          puts "#{index + 1}. #{blueprint[:name]} (ID: #{blueprint[:id]})"
          puts "   Description: #{blueprint[:description]}"
          puts "   Categories: #{categories}" unless categories.empty?
          puts "   Created: #{blueprint[:created_at]}"
          puts ""
        end

        print "Enter the number of the blueprint to delete (1-#{blueprints.length}), or 'q' to quit: "
        response = $stdin.gets.chomp

        if response.downcase == 'q'
          puts "❌ Operation cancelled".colorize(:yellow)
          return nil
        end

        index = response.to_i - 1
        if index >= 0 && index < blueprints.length
          blueprints[index][:id]
        else
          puts "❌ Invalid selection".colorize(:red)
          nil
        end
      end

      def confirm_deletion?(blueprint)
        puts "\n#{'=' * 60}"
        puts "🗑️  Blueprint Deletion Confirmation".colorize(:red)
        puts "=" * 60
        puts "ID: #{blueprint[:id]}"
        puts "Name: #{blueprint[:name]}"
        puts "Description: #{blueprint[:description]}"

        categories = blueprint[:categories].map { |c| c[:title] }.join(', ')
        puts "Categories: #{categories}" unless categories.empty?

        puts "Created: #{blueprint[:created_at]}"
        puts "Updated: #{blueprint[:updated_at]}"
        puts "Code length: #{blueprint[:code].length} characters"
        puts ""

        # Show first few lines of code as preview
        code_lines = blueprint[:code].lines
        puts "Code preview (first 5 lines):"
        code_lines.first(5).each_with_index do |line, i|
          puts "  #{i + 1}: #{line.chomp}"
        end
        puts "  ..." if code_lines.length > 5
        puts ""

        puts "⚠️  WARNING: This action cannot be undone!".colorize(:yellow)
        puts "The blueprint and all its metadata will be permanently deleted.".colorize(:yellow)
        puts ""

        print "Are you sure you want to delete this blueprint? (y/N): "
        response = $stdin.gets.chomp.downcase

        if ['y', 'yes'].include?(response)
          puts "✅ Deletion confirmed".colorize(:green)
          true
        else
          puts "❌ Deletion cancelled".colorize(:yellow)
          false
        end
      end
    end
  end
end
end