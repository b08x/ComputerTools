# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'colorize'

module ComputerTools
  class Configuration
    def initialize
      @config_file = File.expand_path('~/.config/computertools/config.yml')
      load_config
    end

    def config
      @config_data
    end

    def interactive_setup
      puts "🔧 ComputerTools Configuration Setup".colorize(:blue)
      puts "=" * 40

      @config_data ||= default_config

      # Configure paths
      configure_paths
      configure_display
      configure_restic
      configure_terminals

      save_config
      puts "\n✅ Configuration saved to #{@config_file}".colorize(:green)
    end

    # Compatibility method for the fetch pattern used in the original code
    def fetch(*keys)
      current = @config_data
      keys.each do |key|
        current = current[key]
        return nil if current.nil?
      end
      current
    end

    private

    def load_config
      if File.exist?(@config_file)
        @config_data = YAML.load_file(@config_file)
        puts "📁 Loaded configuration from #{@config_file}".colorize(:green) if ENV['DEBUG']
      else
        @config_data = default_config
        puts "⚠️  Using default configuration. Run 'latest-changes config' to customize.".colorize(:yellow)
      end
    end

    def save_config
      FileUtils.mkdir_p(File.dirname(@config_file))
      File.write(@config_file, YAML.dump(@config_data))
    end

    def default_config
      {
        'paths' => {
          'home_dir' => File.expand_path('~'),
          'restic_mount_point' => File.expand_path('~/mnt/restic'),
          'restic_repo' => ENV['RESTIC_REPOSITORY'] || '/path/to/restic/repo'
        },
        'display' => {
          'time_format' => '%Y-%m-%d %H:%M:%S'
        },
        'restic' => {
          'mount_timeout' => 60
        },
        'terminals' => {
          'preferred_order' => [
            { 'cmd' => 'alacritty', 'args' => '-e' },
            { 'cmd' => 'kitty', 'args' => '-e' },
            { 'cmd' => 'gnome-terminal', 'args' => '--' },
            { 'cmd' => 'konsole', 'args' => '-e' },
            { 'cmd' => 'xterm', 'args' => '-e' }
          ]
        }
      }
    end

    def configure_paths
      puts "\n📁 Path Configuration".colorize(:blue)
      
      begin
        print "Home directory [#{@config_data['paths']['home_dir']}]: ".colorize(:cyan)
        STDOUT.flush
        input = STDIN.gets&.chomp
        @config_data['paths']['home_dir'] = input unless input.nil? || input.empty?

        print "Restic mount point [#{@config_data['paths']['restic_mount_point']}]: ".colorize(:cyan)
        STDOUT.flush
        input = STDIN.gets&.chomp
        @config_data['paths']['restic_mount_point'] = input unless input.nil? || input.empty?

        print "Restic repository [#{@config_data['paths']['restic_repo']}]: ".colorize(:cyan)
        STDOUT.flush
        input = STDIN.gets&.chomp
        @config_data['paths']['restic_repo'] = input unless input.nil? || input.empty?
      rescue IOError, Errno::ENOENT => e
        puts "\n⚠️  Interactive input not available. Using defaults.".colorize(:yellow)
        puts "   Error: #{e.message}" if ENV['DEBUG']
      end
    end

    def configure_display
      puts "\n🎨 Display Configuration".colorize(:blue)
      
      begin
        print "Time format [#{@config_data['display']['time_format']}]: ".colorize(:cyan)
        STDOUT.flush
        input = STDIN.gets&.chomp
        @config_data['display']['time_format'] = input unless input.nil? || input.empty?
      rescue IOError, Errno::ENOENT => e
        puts "\n⚠️  Interactive input not available. Using defaults.".colorize(:yellow)
        puts "   Error: #{e.message}" if ENV['DEBUG']
      end
    end

    def configure_restic
      puts "\n📦 Restic Configuration".colorize(:blue)
      
      begin
        print "Mount timeout in seconds [#{@config_data['restic']['mount_timeout']}]: ".colorize(:cyan)
        STDOUT.flush
        input = STDIN.gets&.chomp
        @config_data['restic']['mount_timeout'] = input.to_i unless input.nil? || input.empty?
      rescue IOError, Errno::ENOENT => e
        puts "\n⚠️  Interactive input not available. Using defaults.".colorize(:yellow)
        puts "   Error: #{e.message}" if ENV['DEBUG']
      end
    end

    def configure_terminals
      puts "\n💻 Terminal Configuration".colorize(:blue)
      puts "Current preferred terminals:".colorize(:cyan)
      
      @config_data['terminals']['preferred_order'].each_with_index do |terminal, i|
        puts "  #{i + 1}. #{terminal['cmd']} #{terminal['args']}"
      end
      
      begin
        puts "\nPress Enter to keep current configuration, or type 'edit' to modify:"
        STDOUT.flush
        input = STDIN.gets&.chomp
        
        return unless input&.downcase == 'edit'
        
        puts "Enter terminal configurations (cmd args), one per line. Empty line to finish:"
        terminals = []
        
        loop do
          print "Terminal #{terminals.length + 1}: ".colorize(:cyan)
          STDOUT.flush
          input = STDIN.gets&.chomp
          break if input.nil? || input.empty?
          
          parts = input.split(' ', 2)
          if parts.length >= 2
            terminals << { 'cmd' => parts[0], 'args' => parts[1] }
          else
            puts "⚠️  Invalid format. Use: command arguments".colorize(:yellow)
          end
        end
        
        @config_data['terminals']['preferred_order'] = terminals unless terminals.empty?
      rescue IOError, Errno::ENOENT => e
        puts "\n⚠️  Interactive input not available. Using defaults.".colorize(:yellow)
        puts "   Error: #{e.message}" if ENV['DEBUG']
      end
    end
  end
end