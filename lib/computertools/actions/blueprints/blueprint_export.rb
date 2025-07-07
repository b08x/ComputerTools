# frozen_string_literal: true

module ComputerTools
  module Actions
    module Blueprints
      class BlueprintExport < Sublayer::Actions::Base
      def initialize(id:, output_path: nil, include_metadata: false)
        @id = id
        @output_path = output_path
        @include_metadata = include_metadata
        @db = ComputerTools::Wrappers::BlueprintDatabase.new
      end

      def call
        puts "📤 Exporting blueprint #{@id}...".colorize(:blue)
        
        blueprint = @db.get_blueprint(@id)
        unless blueprint
          puts "❌ Blueprint #{@id} not found".colorize(:red)
          return false
        end

        # Generate output path if not provided
        @output_path ||= generate_output_path(blueprint)
        
        # Check if file already exists
        if File.exist?(@output_path)
          unless confirm_overwrite
            puts "❌ Export cancelled".colorize(:yellow)
            return false
          end
        end

        # Export the blueprint
        export_success = export_blueprint(blueprint)
        
        if export_success
          puts "✅ Blueprint exported to: #{@output_path}".colorize(:green)
          show_export_summary(blueprint)
          true
        else
          puts "❌ Failed to export blueprint".colorize(:red)
          false
        end
      rescue => e
        puts "❌ Error exporting blueprint: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def generate_output_path(blueprint)
        # Create safe filename from blueprint name
        safe_name = (blueprint[:name] || 'blueprint').gsub(/[^a-zA-Z0-9_-]/, '_').downcase
        extension = detect_file_extension(blueprint[:code])
        
        base_filename = "#{safe_name}_#{@id}#{extension}"
        
        # Check if file exists and add number suffix if needed
        counter = 1
        output_path = base_filename
        
        while File.exist?(output_path)
          name_part = File.basename(base_filename, extension)
          output_path = "#{name_part}_#{counter}#{extension}"
          counter += 1
        end
        
        output_path
      end

      def detect_file_extension(code)
        case code
        when /class\s+\w+.*<.*ApplicationRecord/m, /def\s+\w+.*end/m, /require ['"].*['"]/m
          '.rb'
        when /function\s+\w+\s*\(/m, /const\s+\w+\s*=/m, /import\s+.*from/m
          '.js'
        when /def\s+\w+\s*\(/m, /import\s+\w+/m, /from\s+\w+\s+import/m
          '.py'
        when /#include\s*<.*>/m, /int\s+main\s*\(/m
          '.c'
        when /public\s+class\s+\w+/m, /import\s+java\./m
          '.java'
        when /fn\s+\w+\s*\(/m, /use\s+std::/m
          '.rs'
        when /func\s+\w+\s*\(/m, /package\s+main/m
          '.go'
        when /<\?php/m, /namespace\s+\w+/m
          '.php'
        when /<!DOCTYPE html/mi, /<html/mi
          '.html'
        when /^#!/m
          '' # Script files often have no extension
        else
          '.txt'
        end
      end

      def confirm_overwrite
        print "⚠️  File '#{@output_path}' already exists. Overwrite? (y/N): "
        response = STDIN.gets.chomp.downcase
        response == 'y' || response == 'yes'
      end

      def export_blueprint(blueprint)
        content = build_export_content(blueprint)
        
        begin
          # Ensure directory exists
          dir = File.dirname(@output_path)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
          
          # Write the file
          File.write(@output_path, content)
          true
        rescue => e
          puts "❌ Failed to write file: #{e.message}".colorize(:red)
          false
        end
      end

      def build_export_content(blueprint)
        if @include_metadata
          build_content_with_metadata(blueprint)
        else
          blueprint[:code]
        end
      end

      def build_content_with_metadata(blueprint)
        content = []
        
        # Add metadata as comments based on file type
        comment_style = get_comment_style(@output_path)
        
        content << format_comment("Blueprint Export", comment_style)
        content << format_comment("=" * 50, comment_style)
        content << format_comment("ID: #{blueprint[:id]}", comment_style)
        content << format_comment("Name: #{blueprint[:name]}", comment_style)
        content << format_comment("Description: #{blueprint[:description]}", comment_style)
        
        if blueprint[:categories] && blueprint[:categories].any?
          category_names = blueprint[:categories].map { |cat| cat[:title] }
          content << format_comment("Categories: #{category_names.join(', ')}", comment_style)
        end
        
        content << format_comment("Exported: #{Time.now}", comment_style)
        content << format_comment("=" * 50, comment_style)
        content << ""
        content << blueprint[:code]
        
        content.join("\n")
      end

      def get_comment_style(filename)
        case File.extname(filename).downcase
        when '.rb', '.py', '.sh'
          '#'
        when '.js', '.java', '.c', '.cpp', '.cs', '.go', '.rs', '.php'
          '//'
        when '.html', '.xml'
          '<!--'
        when '.css'
          '/*'
        else
          '#'
        end
      end

      def format_comment(text, style)
        case style
        when '<!--'
          "<!-- #{text} -->"
        when '/*'
          "/* #{text} */"
        else
          "#{style} #{text}"
        end
      end

      def show_export_summary(blueprint)
        puts "\n📋 Export Summary:".colorize(:blue)
        puts "   Blueprint: #{blueprint[:name]} (ID: #{@id})"
        puts "   File: #{@output_path}"
        puts "   Size: #{File.size(@output_path)} bytes"
        puts "   Format: #{@include_metadata ? 'Code with metadata' : 'Code only'}"
        
        if blueprint[:categories] && blueprint[:categories].any?
          category_names = blueprint[:categories].map { |cat| cat[:title] }
          puts "   Categories: #{category_names.join(', ')}"
        end
        
        puts ""
        puts "💡 Tip: Use --include-metadata flag to export with blueprint information".colorize(:cyan)
        puts ""
      end
    end
  end
end
end