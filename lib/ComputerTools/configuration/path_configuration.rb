# frozen_string_literal: true

require 'dry-configurable'

module ComputerTools
  module Configurations
    class PathConfiguration
      include Dry::Configurable

      setting :home_dir, default: File.expand_path('~')

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('paths')

        paths_config = yaml_data['paths']

        instance.configure do |config|
          config.home_dir = paths_config['home_dir'] if paths_config.key?('home_dir')
        end

        instance
      end

      def validate_paths
        validate_home_dir
      end

      def validate_home_dir
        expanded_path = File.expand_path(config.home_dir)
        return if File.directory?(expanded_path)

        raise ArgumentError, "Home directory does not exist: #{expanded_path}"
      end


      def validate!
        validate_paths
      end

      def expanded_home_dir
        File.expand_path(config.home_dir)
      end

    end
  end
end