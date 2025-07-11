# frozen_string_literal: true

module ComputerTools
  module Actions
    class DeepgramConfigAction < Sublayer::Actions::Base
      def initialize(subcommand:)
        @subcommand = subcommand
        @config_file = File.join(__dir__, '..', 'config', 'deepgram.yml')
      end

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
            'model' => 'gemini-1.5-flash-latest',
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
          }
        }

        File.write(@config_file, default_config.to_yaml)

        puts "✅ Configuration created successfully!".colorize(:green)
        puts "📄 Config file: #{@config_file}"

        # Show the created configuration
        display_config(default_config)
        true
      end

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

        return unless formats['markdown']

        puts "   Markdown:"
        puts "     • Include Stats: #{formats['markdown']['include_stats'] || true}"
        puts "     • Include Metadata: #{formats['markdown']['include_metadata'] || true}"
      end

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
