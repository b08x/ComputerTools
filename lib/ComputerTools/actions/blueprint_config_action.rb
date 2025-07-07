# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module ComputerTools
  module Actions
    class BlueprintConfigAction < Sublayer::Actions::Base
      CONFIG_PATH = File.join(__dir__, '..', 'config', 'blueprints.yml')
      
      def initialize(subcommand: 'show')
        @subcommand = subcommand
      end

      def call
        case @subcommand
        when 'show', 'view'
          show_configuration
        when 'setup', 'init', 'edit'
          setup_configuration
        when 'test'
          test_configuration
        when 'reset'
          reset_configuration
        else
          puts "❌ Unknown config subcommand: #{@subcommand}".colorize(:red)
          show_config_help
          false
        end
      rescue => e
        puts "❌ Error managing configuration: #{e.message}".colorize(:red)
        puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
        false
      end

      private

      def show_configuration
        config = load_configuration
        
        puts "\n📋 Blueprint Configuration".colorize(:blue)
        puts "=" * 60
        puts "Config file: #{CONFIG_PATH}"
        puts "File exists: #{File.exist?(CONFIG_PATH) ? 'Yes' : 'No'}"
        puts ""
        
        if config
          puts "Database Configuration:".colorize(:cyan)
          puts "  URL: #{mask_password(config.dig('database', 'url') || 'Not set')}"
          puts ""
          
          puts "AI Configuration:".colorize(:cyan)
          puts "  Provider: #{config.dig('ai', 'provider') || 'Not set'}"
          puts "  Model: #{config.dig('ai', 'model') || 'Not set'}"
          puts "  API Key: #{config.dig('ai', 'api_key') ? 'Set' : 'Not set'}"
          puts ""
          
          puts "Editor Configuration:".colorize(:cyan)
          puts "  Editor: #{config.dig('editor') || 'Not set'}"
          puts "  Auto-save: #{config.dig('auto_save_edits') || 'Not set'}"
          puts ""
          
          puts "Feature Flags:".colorize(:cyan)
          puts "  Auto-description: #{config.dig('features', 'auto_description') || 'Not set'}"
          puts "  Auto-categorization: #{config.dig('features', 'auto_categorize') || 'Not set'}"
          puts "  Debug mode: #{config.dig('debug') || 'Not set'}"
        else
          puts "❌ No configuration found".colorize(:red)
          puts "💡 Run 'blueprint config setup' to create configuration".colorize(:yellow)
        end
        
        puts "=" * 60
        puts ""
        
        # Show environment variables
        show_environment_variables
        
        true
      end

      def setup_configuration
        puts "🔧 Blueprint Configuration Setup".colorize(:blue)
        puts "=" * 50
        puts ""
        
        config = load_configuration || {}
        
        # Database configuration
        puts "📊 Database Configuration".colorize(:cyan)
        current_db = config.dig('database', 'url') || 'postgres://localhost/blueprints_development'
        db_url = prompt_for_input("Database URL", current_db)
        
        config['database'] = { 'url' => db_url }
        
        # AI configuration
        puts "\n🤖 AI Configuration".colorize(:cyan)
        current_provider = config.dig('ai', 'provider') || 'gemini'
        provider = prompt_for_choice("AI Provider", ['gemini', 'openai'], current_provider)
        
        current_model = config.dig('ai', 'model') || (provider == 'gemini' ? 'text-embedding-004' : 'text-embedding-3-small')
        model = prompt_for_input("AI Model", current_model)
        
        puts "💡 Set API key via environment variable:".colorize(:yellow)
        puts "   export GEMINI_API_KEY=your_key_here" if provider == 'gemini'
        puts "   export OPENAI_API_KEY=your_key_here" if provider == 'openai'
        
        config['ai'] = {
          'provider' => provider,
          'model' => model
        }
        
        # Editor configuration
        puts "\n✏️  Editor Configuration".colorize(:cyan)
        current_editor = config.dig('editor') || ENV['EDITOR'] || ENV['VISUAL'] || 'vim'
        editor = prompt_for_input("Preferred editor", current_editor)
        
        current_auto_save = config.dig('auto_save_edits')
        auto_save = prompt_for_boolean("Auto-save edits", current_auto_save.nil? ? true : current_auto_save)
        
        config['editor'] = editor
        config['auto_save_edits'] = auto_save
        
        # Feature flags
        puts "\n🎛️  Feature Configuration".colorize(:cyan)
        current_auto_desc = config.dig('features', 'auto_description')
        auto_desc = prompt_for_boolean("Auto-generate descriptions", current_auto_desc.nil? ? true : current_auto_desc)
        
        current_auto_cat = config.dig('features', 'auto_categorize')
        auto_cat = prompt_for_boolean("Auto-generate categories", current_auto_cat.nil? ? true : current_auto_cat)
        
        current_debug = config.dig('debug')
        debug = prompt_for_boolean("Debug mode", current_debug || false)
        
        config['features'] = {
          'auto_description' => auto_desc,
          'auto_categorize' => auto_cat
        }
        config['debug'] = debug
        
        # Save configuration
        puts "\n💾 Saving Configuration".colorize(:blue)
        save_success = save_configuration(config)
        
        if save_success
          puts "✅ Configuration saved successfully!".colorize(:green)
          puts "📁 Config file: #{CONFIG_PATH}".colorize(:cyan)
          puts ""
          puts "🧪 Run 'blueprint config test' to validate the configuration".colorize(:yellow)
        else
          puts "❌ Failed to save configuration".colorize(:red)
        end
        
        save_success
      end

      def test_configuration
        puts "🧪 Testing Blueprint Configuration".colorize(:blue)
        puts "=" * 50
        
        config = load_configuration
        unless config
          puts "❌ No configuration found".colorize(:red)
          return false
        end
        
        all_tests_passed = true
        
        # Test database connection
        puts "\n📊 Testing database connection...".colorize(:cyan)
        db_success = test_database_connection(config)
        all_tests_passed &&= db_success
        
        # Test AI API
        puts "\n🤖 Testing AI API connection...".colorize(:cyan)
        ai_success = test_ai_connection(config)
        all_tests_passed &&= ai_success
        
        # Test editor
        puts "\n✏️  Testing editor availability...".colorize(:cyan)
        editor_success = test_editor(config)
        all_tests_passed &&= editor_success
        
        puts "\n" + "=" * 50
        if all_tests_passed
          puts "✅ All configuration tests passed!".colorize(:green)
        else
          puts "❌ Some configuration tests failed".colorize(:red)
          puts "💡 Run 'blueprint config setup' to fix issues".colorize(:yellow)
        end
        
        all_tests_passed
      end

      def reset_configuration
        if File.exist?(CONFIG_PATH)
          print "⚠️  This will delete the existing configuration. Continue? (y/N): "
          response = STDIN.gets.chomp.downcase
          
          if response == 'y' || response == 'yes'
            File.delete(CONFIG_PATH)
            puts "✅ Configuration reset successfully".colorize(:green)
            puts "💡 Run 'blueprint config setup' to create new configuration".colorize(:yellow)
            true
          else
            puts "❌ Reset cancelled".colorize(:yellow)
            false
          end
        else
          puts "ℹ️  No configuration file found to reset".colorize(:blue)
          true
        end
      end

      def show_config_help
        puts <<~HELP
          Blueprint Configuration Commands:

          blueprint config show     Show current configuration
          blueprint config setup    Interactive configuration setup
          blueprint config test     Test configuration connectivity
          blueprint config reset    Reset configuration to defaults

          Configuration is stored in: #{CONFIG_PATH}
        HELP
      end

      def load_configuration
        return nil unless File.exist?(CONFIG_PATH)
        YAML.load_file(CONFIG_PATH)
      rescue => e
        puts "⚠️  Error loading configuration: #{e.message}".colorize(:yellow)
        nil
      end

      def save_configuration(config)
        # Ensure directory exists
        config_dir = File.dirname(CONFIG_PATH)
        FileUtils.mkdir_p(config_dir) unless Dir.exist?(config_dir)
        
        File.write(CONFIG_PATH, config.to_yaml)
        true
      rescue => e
        puts "❌ Error saving configuration: #{e.message}".colorize(:red)
        false
      end

      def show_environment_variables
        puts "🌍 Environment Variables:".colorize(:blue)
        
        env_vars = {
          'GEMINI_API_KEY' => ENV['GEMINI_API_KEY'],
          'OPENAI_API_KEY' => ENV['OPENAI_API_KEY'],
          'BLUEPRINT_DATABASE_URL' => ENV['BLUEPRINT_DATABASE_URL'],
          'DATABASE_URL' => ENV['DATABASE_URL'],
          'EDITOR' => ENV['EDITOR'],
          'VISUAL' => ENV['VISUAL']
        }
        
        env_vars.each do |key, value|
          status = value ? 'Set' : 'Not set'
          puts "  #{key}: #{status}"
        end
        puts ""
      end

      def test_database_connection(config)
        begin
          require 'sequel'
          db_url = config.dig('database', 'url')
          db = Sequel.connect(db_url)
          db.test_connection
          puts "✅ Database connection successful".colorize(:green)
          true
        rescue => e
          puts "❌ Database connection failed: #{e.message}".colorize(:red)
          false
        end
      end

      def test_ai_connection(config)
        # This is a simplified test - in reality you'd make an actual API call
        provider = config.dig('ai', 'provider')
        api_key = case provider
                  when 'gemini'
                    ENV['GEMINI_API_KEY']
                  when 'openai'
                    ENV['OPENAI_API_KEY']
                  end
        
        if api_key
          puts "✅ AI API key found for #{provider}".colorize(:green)
          true
        else
          puts "❌ AI API key not found for #{provider}".colorize(:red)
          false
        end
      end

      def test_editor(config)
        editor = config.dig('editor')
        if system("which #{editor} > /dev/null 2>&1")
          puts "✅ Editor '#{editor}' found".colorize(:green)
          true
        else
          puts "❌ Editor '#{editor}' not found".colorize(:red)
          false
        end
      end

      def prompt_for_input(prompt, default = nil)
        print "#{prompt}"
        print " [#{default}]" if default
        print ": "
        
        input = STDIN.gets.chomp
        input.empty? ? default : input
      end

      def prompt_for_choice(prompt, choices, default = nil)
        puts "#{prompt} (#{choices.join('/')})"
        print default ? "[#{default}]: " : ": "
        
        input = STDIN.gets.chomp
        input.empty? ? default : input
      end

      def prompt_for_boolean(prompt, default = nil)
        default_text = case default
                      when true then ' [Y/n]'
                      when false then ' [y/N]'
                      else ' [y/n]'
                      end
        
        print "#{prompt}#{default_text}: "
        input = STDIN.gets.chomp.downcase
        
        case input
        when 'y', 'yes', 'true'
          true
        when 'n', 'no', 'false'
          false
        else
          default
        end
      end

      def mask_password(url)
        return url unless url.include?(':') && url.include?('@')
        url.gsub(/:[^:@]*@/, ':***@')
      end
    end
  end
end