# frozen_string_literal: true

module ComputerTools
  module Actions
    # Manages the Deepgram tool's configuration settings stored in `config/deepgram.yml`.
    #
    # This action class provides the backend logic for a command-line interface (CLI)
    # to interact with the configuration file. It supports showing the current
    # configuration, creating a default setup, opening the file for editing, and
    # resetting it to its default state.
    #
    # @example Initializing and running the setup command
    #   ComputerTools::Actions::DeepgramConfigAction.new(subcommand: 'setup').call
    #
    # @example Showing the current configuration
    #   ComputerTools::Actions::DeepgramConfigAction.new(subcommand: 'show').call
    class DeepgramConfigAction < ComputerTools::Actions::BaseAction
      # Initializes the configuration action.
      #
      # @param subcommand [String] The configuration command to execute.
      #   Valid options are 'show', 'setup', 'edit', and 'reset'.
      def initialize(subcommand:)
        @subcommand = subcommand
        @config_file = File.join(__dir__, '..', '..', 'config', 'deepgram.yml')
      end

      # Executes the specified configuration subcommand.
      #
      # This is the main entry point for the action. It routes the flow to the
      # appropriate private method based on the subcommand provided during
      # initialization. If an unknown subcommand is given, it displays help text.
      #
      # @return [Boolean] Returns `true` if the action was successful, `false` otherwise.
      def call
        case @subcommand
        when 'show'
          show_config
        when 'setup'
          setup_config
        when 'edit'
          edit_config
        when 'reset'
          reset_config
        else
          puts "❌ Unknown config subcommand: #{@subcommand}".colorize(:red)
          show_help
          false
        end
      end

      private

      # Displays the current configuration from the YAML file.
      #
      # If the configuration file does not exist, it prompts the user to run
      # the `setup` command.
      #
      # @return [Boolean] Returns `true`.
      def show_config
        puts "🔧 Deepgram Configuration".colorize(:blue)
        puts "=" * 50

        if File.exist?(@config_file)
          config = YAML.load_file(@config_file)
          display_config(config)
        else
          puts "⚠️  No configuration file found".colorize(:yellow)
          puts "Run 'deepgram config setup' to create one"
        end

        puts "\nConfiguration file: #{@config_file}"
        true
      end

      # Creates a new default configuration file.
      #
      # This method generates a `deepgram.yml` file with default settings for
      # output formats, AI processing, and other tool features. It will create the
      # `config` directory if it doesn't already exist.
      #
      # @return [Boolean] Returns `true` after creating the file.
      def setup_config
        puts "🚀 Setting up Deepgram configuration...".colorize(:blue)

        # Ensure config directory exists
        FileUtils.mkdir_p(File.dirname(@config_file))

        # Create default configuration
        default_config = {
          'output' => {
            'default_format' => 'markdown',
            'auto_timestamp' => true,
            'include_confidence' => true
          },
          'ai' => {
            'provider' => 'gemini',
            'model' => 'gemini-2.0-flash',
            'enable_insights' => true,
            'enable_summaries' => true
          },
          'formats' => {
            'srt' => {
              'include_milliseconds' => true,
              'line_length' => 42
            },
            'markdown' => {
              'include_stats' => true,
              'include_metadata' => true
            }
          },
          'speaker_diarization' => {
            'enable' => false,
            'confidence_threshold' => 0.8,
            'label_format' => '[Speaker %d]: ',
            'merge_consecutive_segments' => true,
            'min_segment_duration' => 1.0,
            'max_speakers' => 10
          }
        }

        File.write(@config_file, default_config.to_yaml)

        puts "✅ Configuration created successfully!".colorize(:green)
        puts "📄 Config file: #{@config_file}"

        # Show the created configuration
        display_config(default_config)
        true
      end

      # Opens the configuration file in the user's default text editor.
      #
      # It checks for the `EDITOR` or `VISUAL` environment variables, falling
      # back to `nano` if neither is set.
      #
      # @return [Boolean] Returns `true` on success, `false` if the config file
      #   does not exist.
      def edit_config
        unless File.exist?(@config_file)
          puts "❌ Configuration file not found".colorize(:red)
          puts "Run 'deepgram config setup' first"
          return false
        end

        editor = ENV['EDITOR'] || ENV['VISUAL'] || 'nano'
        system("#{editor} #{@config_file}")

        puts "✅ Configuration updated".colorize(:green)
        true
      end

      # Deletes the existing configuration file.
      #
      # This effectively resets the configuration. The user is prompted to run
      # the `setup` command to create a new default configuration.
      #
      # @return [Boolean] Returns `true`.
      def reset_config
        if File.exist?(@config_file)
          File.delete(@config_file)
          puts "✅ Configuration reset successfully".colorize(:green)
        else
          puts "⚠️  No configuration file to reset".colorize(:yellow)
        end

        puts "Run 'deepgram config setup' to create a new configuration"
        true
      end

      # Prints a formatted view of the configuration hash to the console.
      #
      # @param config [Hash] The configuration hash to display.
      # @return [nil, Boolean] Returns `nil` if markdown settings are present,
      #   otherwise returns `true`.
      def display_config(config)
        puts "\n📋 Current Configuration:".colorize(:cyan)

        puts "\n🎯 Output Settings:"
        output = config['output'] || {}
        puts "   • Default Format: #{output['default_format'] || 'markdown'}"
        puts "   • Auto Timestamp: #{output['auto_timestamp'] || true}"
        puts "   • Include Confidence: #{output['include_confidence'] || true}"

        puts "\n🤖 AI Settings:"
        ai = config['ai'] || {}
        puts "   • Provider: #{ai['provider'] || 'gemini'}"
        puts "   • Model: #{ai['model'] || 'gemini-1.5-flash-latest'}"
        puts "   • Enable Insights: #{ai['enable_insights'] || true}"
        puts "   • Enable Summaries: #{ai['enable_summaries'] || true}"

        puts "\n📄 Format Settings:"
        formats = config['formats'] || {}

        if formats['srt']
          puts "   SRT:"
          puts "     • Include Milliseconds: #{formats['srt']['include_milliseconds'] || true}"
          puts "     • Line Length: #{formats['srt']['line_length'] || 42}"
        end

        if formats['markdown']
          puts "   Markdown:"
          puts "     • Include Stats: #{formats['markdown']['include_stats'] || true}"
          puts "     • Include Metadata: #{formats['markdown']['include_metadata'] || true}"
        end

        puts "\n🎤 Speaker Diarization Settings:"
        speaker = config['speaker_diarization'] || {}
        puts "   • Enable: #{speaker['enable'] || false}"
        puts "   • Confidence Threshold: #{speaker['confidence_threshold'] || 0.8}"
        puts "   • Label Format: \"#{speaker['label_format'] || '[Speaker %d]: '}\""
        puts "   • Merge Consecutive Segments: #{speaker['merge_consecutive_segments'] || true}"
        puts "   • Min Segment Duration: #{speaker['min_segment_duration'] || 1.0}s"
        puts "   • Max Speakers: #{speaker['max_speakers'] || 10}"
      end

      # Displays a help message with the available subcommands.
      #
      # @return [nil]
      def show_help
        puts <<~HELP
          Configuration Commands:

          deepgram config show           Show current configuration
          deepgram config setup          Create default configuration
          deepgram config edit           Edit configuration file
          deepgram config reset          Reset configuration to defaults
        HELP
      end
    end
  end
end