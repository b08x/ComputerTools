# frozen_string_literal: true

require 'dry-configurable'

module ComputerTools
  module Configurations
    class DisplayConfiguration
      include Dry::Configurable

      setting :time_format, default: '%Y-%m-%d %H:%M:%S'

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('display')

        display_config = yaml_data['display']

        instance.configure do |config|
          config.time_format = display_config['time_format'] if display_config.key?('time_format')
        end

        instance
      end

      def format_time(time)
        time.strftime(config.time_format)
      end

      def validate_time_format
        # Test the format string with a sample time

        Time.now.strftime(config.time_format)
      rescue StandardError => e
        raise ArgumentError, "Invalid time format '#{config.time_format}': #{e.message}"
      end

      def validate!
        validate_time_format
      end
    end
  end
end