# frozen_string_literal: true

require 'sequel'
require 'net/http'
require 'json'
require 'uri'

module ComputerTools
  module Wrappers
    # Direct database interface for blueprint operations with embedding support
    # Handles PostgreSQL operations and Google Gemini API for vector embeddings
    class BlueprintDatabase
      EMBEDDING_MODEL = 'text-embedding-004'
      EMBEDDING_DIMENSIONS = 768

      attr_reader :db

      def initialize(database_url: nil)
        @database_url = database_url || load_database_url
        @db = connect_to_database
        @gemini_api_key = load_gemini_api_key

        validate_database_schema
      end

      # Create a new blueprint with AI-generated metadata and embeddings
      def create_blueprint(code:, name: nil, description: nil, categories: [])
        @db.transaction do
          # Insert blueprint record
          blueprint_id = @db[:blueprints].insert(
            code: code,
            name: name,
            description: description,
            embedding: generate_embedding(name: name, description: description),
            created_at: Time.now,
            updated_at: Time.now
          )

          # Handle categories if provided
          insert_blueprint_categories(blueprint_id, categories) if categories.any?

          # Return the created blueprint
          get_blueprint(blueprint_id)
        end
      rescue StandardError => e
        puts "❌ Error creating blueprint: #{e.message}".colorize(:red)
        nil
      end

      # Get a specific blueprint by ID
      def get_blueprint(id)
        blueprint = @db[:blueprints].where(id: id).first
        return nil unless blueprint

        # Add categories
        blueprint[:categories] = get_blueprint_categories(id)
        blueprint
      end

      # List all blueprints with optional pagination
      def list_blueprints(limit: 100, offset: 0)
        blueprints = @db[:blueprints]
          .order(Sequel.desc(:created_at))
          .limit(limit)
          .offset(offset)
          .all

        # Add categories for each blueprint
        blueprints.each do |blueprint|
          blueprint[:categories] = get_blueprint_categories(blueprint[:id])
        end

        blueprints
      end

      # Search blueprints by vector similarity
      def search_blueprints(query:, limit: 10)
        # Generate embedding for the search query
        query_embedding = generate_embedding_for_text(query)
        return [] unless query_embedding

        # Perform vector similarity search using pgvector
        results = @db.fetch(
          "SELECT *, embedding <-> ? AS distance
           FROM blueprints
           ORDER BY embedding <-> ?
           LIMIT ?",
          query_embedding, query_embedding, limit
        ).all

        # Add categories for each result
        results.each do |blueprint|
          blueprint[:categories] = get_blueprint_categories(blueprint[:id])
        end

        results
      end

      # Delete a blueprint and all associated records
      def delete_blueprint(id)
        @db.transaction do
          # Delete category associations
          @db[:blueprints_categories].where(blueprint_id: id).delete

          # Delete the blueprint
          deleted_count = @db[:blueprints].where(id: id).delete
          deleted_count > 0
        end
      rescue StandardError => e
        puts "❌ Error deleting blueprint: #{e.message}".colorize(:red)
        false
      end

      # Update a blueprint (used for edit operations)
      def update_blueprint(id:, code: nil, name: nil, description: nil, categories: nil)
        updates = { updated_at: Time.now }
        updates[:code] = code if code
        updates[:name] = name if name
        updates[:description] = description if description

        # Regenerate embedding if name or description changed
        if name || description
          current = get_blueprint(id)
          new_name = name || current[:name]
          new_description = description || current[:description]
          updates[:embedding] = generate_embedding(name: new_name, description: new_description)
        end

        @db.transaction do
          # Update blueprint
          @db[:blueprints].where(id: id).update(updates)

          # Update categories if provided
          if categories
            @db[:blueprints_categories].where(blueprint_id: id).delete
            insert_blueprint_categories(id, categories)
          end

          # Return updated blueprint
          get_blueprint(id)
        end
      rescue StandardError => e
        puts "❌ Error updating blueprint: #{e.message}".colorize(:red)
        nil
      end

      # Get all available categories
      def get_categories
        @db[:categories].all
      end

      # Create a new category
      def create_category(title:, description: nil)
        @db[:categories].insert(
          title: title,
          created_at: Time.now,
          updated_at: Time.now
        )
      rescue Sequel::UniqueConstraintViolation
        # Category already exists, find and return it
        @db[:categories].where(title: title).first[:id]
      end

      # Database statistics
      def stats
        {
          total_blueprints: @db[:blueprints].count,
          total_categories: @db[:categories].count,
          database_url: @database_url.gsub(/:[^:@]*@/, ':***@') # Hide password
        }
      end

      private

      def load_database_url
        # Check configuration file first
        config_file = File.join(__dir__, '..', 'config', 'blueprints.yml')
        if File.exist?(config_file)
          config = YAML.load_file(config_file)
          return config['database']['url'] if config['database']&.[]('url')
        end

        # Fall back to environment variables
        ENV['BLUEPRINT_DATABASE_URL'] ||
          ENV['DATABASE_URL'] ||
          'postgres://localhost/blueprints_development'
      end

      def load_gemini_api_key
        ENV['GEMINI_API_KEY'] || ENV.fetch('GOOGLE_API_KEY', nil)
      end

      def connect_to_database
        Sequel.connect(@database_url)
      rescue StandardError => e
        puts "❌ Failed to connect to database: #{e.message}".colorize(:red)
        puts "Database URL: #{@database_url.gsub(/:[^:@]*@/, ':***@')}".colorize(:yellow)
        raise e
      end

      def validate_database_schema
        required_tables = %i[blueprints categories blueprints_categories]

        required_tables.each do |table|
          unless @db.table_exists?(table)
            raise "Missing required table: #{table}. Please ensure the blueprints database is properly set up."
          end
        end

        # Check for vector extension
        return if @db.fetch("SELECT 1 FROM pg_extension WHERE extname = 'vector'").first

        puts "⚠️  Warning: pgvector extension not found. Vector search may not work.".colorize(:yellow)
      end

      # Generate embedding vector for name + description combination
      def generate_embedding(name:, description:)
        content = { name: name, description: description }.to_json
        generate_embedding_for_text(content)
      end

      # Generate embedding vector for arbitrary text using Google Gemini API
      def generate_embedding_for_text(text)
        unless @gemini_api_key
          puts "⚠️  Warning: No Gemini API key found. Skipping embedding generation.".colorize(:yellow)
          return nil
        end

        uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{EMBEDDING_MODEL}:embedContent")
        uri.query = URI.encode_www_form(key: @gemini_api_key)

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = {
          model: "models/#{EMBEDDING_MODEL}",
          content: {
            parts: [{ text: text }]
          }
        }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        if response.code == '200'
          data = JSON.parse(response.body)
          embedding = data.dig('embedding', 'values')

          if embedding && embedding.length == EMBEDDING_DIMENSIONS
            "[#{embedding.join(',')}]" # Format as PostgreSQL vector
          else
            puts "⚠️  Warning: Invalid embedding dimensions received".colorize(:yellow)
            nil
          end
        else
          puts "❌ Error generating embedding: #{response.code} #{response.message}".colorize(:red)
          puts response.body if ENV['DEBUG']
          nil
        end
      rescue StandardError => e
        puts "❌ Error calling Gemini API: #{e.message}".colorize(:red)
        nil
      end

      def get_blueprint_categories(blueprint_id)
        @db.fetch(
          "SELECT c.* FROM categories c
           JOIN blueprints_categories bc ON c.id = bc.category_id
           WHERE bc.blueprint_id = ?",
          blueprint_id
        ).all
      end

      def insert_blueprint_categories(blueprint_id, category_names)
        category_names.each do |category_name|
          category_name = category_name.strip
          next if category_name.empty?

          # Find or create category
          category = @db[:categories].where(title: category_name).first
          category_id = if category
                          category[:id]
                        else
                          create_category(title: category_name)
                        end

          # Link blueprint to category
          @db[:blueprints_categories].insert_ignore.insert(
            blueprint_id: blueprint_id,
            category_id: category_id
          )
        end
      end
    end
    end
  end
end