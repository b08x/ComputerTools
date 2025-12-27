# frozen_string_literal: true

require 'dry-configurable'

module ComputerTools
  module Configurations
    class BackupConfiguration
      include Dry::Configurable

      setting :mount_timeout, default: 60

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('restic')

        restic_config = yaml_data['restic']

        instance.configure do |config|
          config.mount_timeout = restic_config['mount_timeout'] if restic_config.key?('mount_timeout')
        end

        instance
      end

      def validate_timeout
        return if config.mount_timeout.is_a?(Integer) && config.mount_timeout > 0

        raise ArgumentError, "Mount timeout must be a positive integer, got: #{config.mount_timeout}"
      end

      def validate!
        validate_timeout
      end
    end
  end
end