# frozen_string_literal: true

module ComputerTools
  module Actions
    module Blueprints
      class BlueprintSearchAction < Sublayer::Actions::Base
      def initialize(query:, limit: 10, semantic: true)
        @query = query
        @limit = limit
        @semantic = semantic
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        puts "🔍 Searching for: '#{@query}'...".colorize(:blue)
        
        if @semantic
          results = semantic_search
        else
          results = text_search
        end
        
        if results.empty?
          puts "📭 No blueprints found matching '#{@query}'".colorize(:yellow)
          return true
        end

        puts "✅ Found #{results.length} matching blueprints".colorize(:green)
        display_search_results(results)
        
        true
      rescue => e
        puts "❌ Error searching blueprints: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def semantic_search
        # Use vector similarity search for semantic matching
        @db.search_blueprints(query: @query, limit: @limit)
      end

      def text_search
        # Fallback to simple text search in name, description, and code
        blueprints = @db.list_blueprints(limit: 1000) # Get more for filtering
        
        query_words = @query.downcase.split(/\s+/)
        
        results = blueprints.select do |blueprint|
          searchable_text = [
            blueprint[:name],
            blueprint[:description],
            blueprint[:code],
            blueprint[:categories].map { |c| c[:title] }.join(' ')
          ].compact.join(' ').downcase
          
          # Check if all query words are present
          query_words.all? { |word| searchable_text.include?(word) }
        end
        
        # Sort by relevance (simple scoring)
        results.sort_by do |blueprint|
          score = calculate_text_relevance(blueprint, query_words)
          -score # Negative for descending order
        end.first(@limit)
      end

      def calculate_text_relevance(blueprint, query_words)
        score = 0
        
        # Higher weight for matches in name and description
        name_text = (blueprint[:name] || '').downcase
        desc_text = (blueprint[:description] || '').downcase
        code_text = blueprint[:code].downcase
        
        query_words.each do |word|
          score += 10 if name_text.include?(word)
          score += 5 if desc_text.include?(word)
          score += 1 if code_text.include?(word)
        end
        
        score
      end

      def display_search_results(results)
        puts "\n" + "=" * 120
        puts "🔍 Search Results for: '#{@query}'".colorize(:blue)
        puts "=" * 120
        
        if @semantic && results.first && results.first.key?(:distance)
          # Show similarity scores for semantic search
          printf "%-5s %-30s %-40s %-20s %-10s\n", "ID", "Name", "Description", "Categories", "Score"
          puts "-" * 120
          
          results.each do |blueprint|
            name = truncate_text(blueprint[:name] || 'Untitled', 28)
            description = truncate_text(blueprint[:description] || 'No description', 38)
            categories = get_category_text(blueprint[:categories])
            similarity = calculate_similarity_percentage(blueprint[:distance])
            
            printf "%-5s %-30s %-40s %-20s %-10s\n", 
                   blueprint[:id], 
                   name, 
                   description, 
                   categories,
                   "#{similarity}%"
          end
        else
          # Standard display for text search
          printf "%-5s %-35s %-50s %-25s\n", "ID", "Name", "Description", "Categories"
          puts "-" * 120
          
          results.each do |blueprint|
            name = truncate_text(blueprint[:name] || 'Untitled', 33)
            description = truncate_text(blueprint[:description] || 'No description', 48)
            categories = get_category_text(blueprint[:categories])
            
            printf "%-5s %-35s %-50s %-25s\n", 
                   blueprint[:id], 
                   name, 
                   description, 
                   categories
          end
        end
        
        puts "=" * 120
        puts ""
        
        # Show usage hints
        show_usage_hints(results)
      end

      def calculate_similarity_percentage(distance)
        # Convert distance to percentage (lower distance = higher similarity)
        # This is a rough approximation - adjust based on your embedding space
        similarity = [100 - (distance * 100), 0].max
        similarity.round(1)
      end

      def get_category_text(categories)
        return 'None' if categories.nil? || categories.empty?
        
        category_names = categories.map { |cat| cat[:title] }
        text = category_names.join(', ')
        truncate_text(text, 23)
      end

      def show_usage_hints(results)
        puts "💡 Next steps:".colorize(:cyan)
        puts "   blueprint view <id>           View full blueprint details"
        puts "   blueprint view <id> --analyze Get AI analysis and suggestions"
        puts "   blueprint edit <id>           Edit a blueprint"
        puts "   blueprint export <id>         Export blueprint code"
        
        if results.any?
          sample_id = results.first[:id]
          puts "\n📋 Example: blueprint view #{sample_id}".colorize(:yellow)
        end
        puts ""
      end

      def truncate_text(text, length)
        return text if text.length <= length
        text[0..length-4] + "..."
      end
    end
  end
end
end