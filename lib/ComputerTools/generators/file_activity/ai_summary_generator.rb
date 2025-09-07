# frozen_string_literal: true

module ComputerTools
  module Generators
    ##
    # Generates AI-powered daily development activity summaries using ruby_llm.
    #
    # This generator takes file activity data and creates intelligent, contextual
    # summaries that provide insights into development patterns, productivity metrics,
    # and actionable recommendations. It leverages ruby_llm's latest MCP protocol
    # to deliver high-quality natural language analysis of coding activities.
    #
    # The AI summaries focus on:
    # - Development workflow analysis
    # - Code change pattern recognition
    # - Productivity insights and metrics
    # - Actionable recommendations for improvement
    #
    class AiSummaryGenerator < ComputerTools::Generators::BaseGenerator
      ##
      # Initializes a new AiSummaryGenerator instance.
      #
      # @param data [Array<Hash>] The array of file activity data
      # @param config [Object] Configuration object for the generator
      # @param time_range [String] Time range for the analysis (e.g., '24h', '7d')
      # @param detail_level [Symbol] Level of detail for the summary (:brief, :detailed, :comprehensive)
      def initialize(data:, config:, time_range: '24h', detail_level: :detailed)
        @data = data
        @config = config
        @time_range = time_range
        @detail_level = detail_level
        @llm_client = initialize_llm_client
      end

      ##
      # Generates and displays the AI-powered summary report.
      #
      # This method analyzes the file activity data using AI and produces
      # a comprehensive summary with insights, metrics, and recommendations.
      #
      # @return [Boolean] Returns true on successful generation, false on error
      def call
        return handle_no_data if @data.empty?

        puts "🤖 Generating AI-powered development summary...".colorize(:blue)
        
        begin
          summary_data = prepare_summary_data
          ai_response = generate_ai_summary(summary_data)
          display_ai_summary(ai_response)
          
          puts "\n✅ AI summary generated successfully!".colorize(:green)
          true
        rescue StandardError => e
          handle_error(e)
          false
        end
      end

      private

      ##
      # Initializes the ruby_llm client with the latest protocol configuration.
      #
      # @return [RubyLLM::Client] Configured LLM client
      def initialize_llm_client
        # Configuration is already loaded by ComputerTools::Config.load
        # Just return RubyLLM since environment variables are set up
        RubyLLM
      end

      ##
      # Prepares structured data for AI analysis.
      #
      # @return [Hash] Structured summary data for LLM processing
      def prepare_summary_data
        stats = calculate_comprehensive_stats
        patterns = analyze_development_patterns
        
        {
          metadata: {
            time_range: @time_range,
            generated_at: Time.now.iso8601,
            total_files: @data.length,
            detail_level: @detail_level
          },
          statistics: stats,
          patterns: patterns,
          files: prepare_file_data_for_ai
        }
      end

      ##
      # Calculates comprehensive development statistics.
      #
      # @return [Hash] Statistical analysis of the development activity
      def calculate_comprehensive_stats
        tracking_counts = @data.group_by { |row| row[:tracking] }.transform_values(&:count)
        modified_files = @data.count { |row| row[:git_status] != '--' }
        
        {
          total_files: @data.length,
          modified_files: modified_files,
          by_tracking: tracking_counts,
          total_additions: @data.sum { |row| row[:additions] },
          total_deletions: @data.sum { |row| row[:deletions] },
          total_chunks: @data.sum { |row| row[:chunks] },
          hours_with_activity: group_files_by_hour.keys.count,
          file_types: analyze_file_types,
          change_intensity: calculate_change_intensity
        }
      end

      ##
      # Analyzes development patterns from the data.
      #
      # @return [Hash] Development pattern analysis
      def analyze_development_patterns
        hourly_activity = group_files_by_hour
        peak_hours = find_peak_activity_hours(hourly_activity)
        
        {
          peak_activity_hours: peak_hours,
          development_rhythm: analyze_development_rhythm(hourly_activity),
          file_change_patterns: analyze_file_change_patterns,
          productivity_indicators: calculate_productivity_indicators
        }
      end

      ##
      # Prepares file data for AI analysis by selecting relevant information.
      #
      # @return [Array<Hash>] Filtered file data for LLM processing
      def prepare_file_data_for_ai
        @data.map do |file|
          {
            file: file[:file],
            tracking: file[:tracking],
            git_status: file[:git_status],
            additions: file[:additions],
            deletions: file[:deletions],
            chunks: file[:chunks],
            modified_time: file[:modified_time]&.strftime('%H:%M')
          }
        end
      end

      ##
      # Generates AI summary using ruby_llm.
      #
      # @param summary_data [Hash] Prepared data for AI analysis
      # @return [String] AI-generated summary
      def generate_ai_summary(summary_data)
        prompt = build_analysis_prompt(summary_data)
        
        # Use the BaseGenerator's generate_llm_content method for consistent API
        with_generation_handling("AI development summary generation") do
          generate_llm_content(
            prompt,
            system_prompt: build_system_prompt,
            temperature: 0.3,
            max_tokens: 1500
          )
        end
      end

      ##
      # Builds the system prompt for the AI analysis.
      #
      # @return [String] System prompt for the LLM
      def build_system_prompt
        <<~SYSTEM
          You are an expert software development analyst specializing in productivity insights and code change analysis. 
          
          Your role is to analyze file activity data and provide actionable insights about development patterns, 
          productivity metrics, and workflow optimization opportunities.
          
          Focus on:
          - Clear, actionable insights
          - Development workflow patterns
          - Productivity trends and recommendations
          - Code change quality indicators
          - Time management observations
          
          Use a professional but friendly tone. Provide specific, data-driven observations.
        SYSTEM
      end

      ##
      # Builds the analysis prompt with the prepared data.
      #
      # @param summary_data [Hash] Data to be analyzed
      # @return [String] Analysis prompt for the LLM
      def build_analysis_prompt(summary_data)
        <<~PROMPT
          Please analyze this development activity data for the last #{@time_range} and provide insights:

          ## Activity Statistics
          - Total files: #{summary_data[:statistics][:total_files]}
          - Modified files: #{summary_data[:statistics][:modified_files]}
          - Lines added: #{summary_data[:statistics][:total_additions]}
          - Lines deleted: #{summary_data[:statistics][:total_deletions]}
          - Code chunks modified: #{summary_data[:statistics][:total_chunks]}
          - Active development hours: #{summary_data[:statistics][:hours_with_activity]}
          
          ## File Tracking Breakdown
          #{format_tracking_breakdown(summary_data[:statistics][:by_tracking])}
          
          ## Development Patterns
          - Peak activity hours: #{summary_data[:patterns][:peak_activity_hours].join(', ')}
          - File types worked on: #{summary_data[:statistics][:file_types].keys.join(', ')}
          - Change intensity: #{summary_data[:statistics][:change_intensity]}
          
          #{build_detail_level_instructions}
          
          Please provide a comprehensive analysis covering:
          1. **Development Summary** - Overview of activity and key accomplishments
          2. **Productivity Insights** - Patterns, efficiency observations, and time distribution
          3. **Code Quality Indicators** - Analysis of change patterns and complexity
          4. **Recommendations** - Actionable suggestions for workflow improvement
          
          Format your response with clear sections and bullet points where appropriate.
        PROMPT
      end

      ##
      # Formats the tracking method breakdown for the prompt.
      #
      # @param tracking_data [Hash] Tracking method counts
      # @return [String] Formatted tracking breakdown
      def format_tracking_breakdown(tracking_data)
        tracking_data.map { |method, count| "- #{method}: #{count} files" }.join("\n")
      end

      ##
      # Builds detail level specific instructions for the AI.
      #
      # @return [String] Detail level instructions
      def build_detail_level_instructions
        case @detail_level
        when :brief
          "\nProvide a concise summary focused on key highlights and top recommendations."
        when :comprehensive
          "\nProvide an extensive analysis with detailed explanations, multiple recommendations, and forward-looking insights."
        else
          "\nProvide a balanced analysis with clear insights and practical recommendations."
        end
      end

      ##
      # Displays the AI-generated summary with formatting.
      #
      # @param ai_response [String] The AI-generated summary
      def display_ai_summary(ai_response)
        puts "\n#{'=' * 80}"
        puts "🤖 AI-POWERED DEVELOPMENT SUMMARY (#{@time_range})".colorize(:blue)
        puts "=" * 80
        
        # Split response into sections and format appropriately
        sections = ai_response.split(/(?=##?\s+)/)
        
        sections.each do |section|
          next if section.strip.empty?
          
          if section.start_with?('##')
            # Header sections
            puts "\n#{section.strip}".colorize(:yellow)
          elsif section.start_with?('#')
            # Main sections
            puts "\n#{section.strip}".colorize(:green)
          else
            # Content
            puts section.strip
          end
        end
        
        puts "\n" + "=" * 80
      end

      ##
      # Groups files by hour of modification.
      #
      # @return [Hash] Files grouped by hour
      def group_files_by_hour
        @data.group_by do |row|
          row[:modified_time].strftime('%Y-%m-%d %H')
        end
      end

      ##
      # Finds peak activity hours from hourly data.
      #
      # @param hourly_data [Hash] Files grouped by hour
      # @return [Array<String>] Peak activity hours
      def find_peak_activity_hours(hourly_data)
        hourly_counts = hourly_data.transform_values(&:count)
        return [] if hourly_counts.empty?
        
        max_activity = hourly_counts.values.max
        peak_hours = hourly_counts.select { |_, count| count == max_activity }.keys
        
        peak_hours.map { |hour| Time.strptime(hour, '%Y-%m-%d %H').strftime('%I %p') }
      end

      ##
      # Analyzes development rhythm patterns.
      #
      # @param hourly_data [Hash] Files grouped by hour
      # @return [String] Development rhythm description
      def analyze_development_rhythm(hourly_data)
        hours = hourly_data.keys.map { |h| Time.strptime(h, '%Y-%m-%d %H').hour }
        return "No activity detected" if hours.empty?
        
        morning_activity = hours.count { |h| h >= 6 && h < 12 }
        afternoon_activity = hours.count { |h| h >= 12 && h < 18 }
        evening_activity = hours.count { |h| h >= 18 && h < 24 }
        
        peak_period = [
          ["Morning", morning_activity],
          ["Afternoon", afternoon_activity], 
          ["Evening", evening_activity]
        ].max_by { |_, count| count }
        
        "#{peak_period[0]} focused (#{peak_period[1]} active hours)"
      end

      ##
      # Analyzes file change patterns.
      #
      # @return [Hash] File change pattern analysis
      def analyze_file_change_patterns
        {
          large_changes: @data.count { |f| f[:additions] + f[:deletions] > 50 },
          small_changes: @data.count { |f| f[:additions] + f[:deletions] <= 10 },
          new_files: @data.count { |f| f[:git_status] == 'A' },
          modified_files: @data.count { |f| f[:git_status] == 'M' }
        }
      end

      ##
      # Analyzes file types in the dataset.
      #
      # @return [Hash] File type distribution
      def analyze_file_types
        extensions = @data.map do |file|
          File.extname(file[:file]).downcase
        end.compact
        
        extensions.group_by(&:itself).transform_values(&:count)
      end

      ##
      # Calculates change intensity metrics.
      #
      # @return [String] Change intensity description
      def calculate_change_intensity
        return "No changes" if @data.empty?
        
        avg_changes = (@data.sum { |f| f[:additions] + f[:deletions] }.to_f / @data.length).round(1)
        
        case avg_changes
        when 0..5 then "Light (#{avg_changes} avg changes/file)"
        when 6..25 then "Moderate (#{avg_changes} avg changes/file)"
        when 26..100 then "Heavy (#{avg_changes} avg changes/file)"
        else "Intensive (#{avg_changes} avg changes/file)"
        end
      end

      ##
      # Calculates productivity indicators.
      #
      # @return [Hash] Productivity metrics
      def calculate_productivity_indicators
        {
          change_to_file_ratio: @data.empty? ? 0 : (@data.sum { |f| f[:additions] + f[:deletions] }.to_f / @data.length).round(2),
          modification_rate: @data.empty? ? 0 : (@data.count { |f| f[:git_status] != '--' }.to_f / @data.length * 100).round(1),
          chunk_complexity: @data.empty? ? 0 : (@data.sum { |f| f[:chunks] }.to_f / @data.length).round(1)
        }
      end

      ##
      # Handles the case where no data is available.
      #
      # @return [Boolean] Always returns true
      def handle_no_data
        puts "ℹ️  No file activity data available for AI analysis".colorize(:cyan)
        true
      end

      ##
      # Handles errors during AI summary generation.
      #
      # @param error [StandardError] The error that occurred
      def handle_error(error)
        puts "❌ Error generating AI summary: #{error.message}".colorize(:red)
        puts "   Falling back to standard reporting...".colorize(:yellow)
        
        if ENV['DEBUG']
          puts "   Full error: #{error.class}: #{error.message}"
          puts "   Backtrace: #{error.backtrace.first(3).join("\n   ")}"
        end
        
        # Fallback to basic summary display
        display_fallback_summary
      end

      ##
      # Displays a fallback summary when AI generation fails.
      def display_fallback_summary
        stats = calculate_comprehensive_stats
        
        puts "\n📊 BASIC DEVELOPMENT SUMMARY (#{@time_range})".colorize(:blue)
        puts "=" * 60
        puts "📁 Files analyzed: #{stats[:total_files]}".colorize(:green)
        puts "🔄 Files modified: #{stats[:modified_files]}".colorize(:yellow)
        puts "📈 Lines added: #{stats[:total_additions]}".colorize(:green)
        puts "📉 Lines removed: #{stats[:total_deletions]}".colorize(:red)
        puts "⏰ Active hours: #{stats[:hours_with_activity]}".colorize(:cyan)
      end
    end
  end
end