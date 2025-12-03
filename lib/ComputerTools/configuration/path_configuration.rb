# frozen_string_literal: true

require 'dry-configurable'

module ComputerTools
  module Configurations
    class PathConfiguration
      include Dry::Configurable

      setting :home_dir, default: File.expand_path('~')
      setting :restic_mount_point, default: File.expand_path('/mnt/restic')
      setting :restic_repo, default: ENV['RESTIC_REPOSITORY'] || '/mnt/ninjabot/backup00/b08x'

      def self.from_yaml(yaml_data)
        instance = new
        return instance unless yaml_data&.dig('paths')

        paths_config = yaml_data['paths']

        instance.configure do |config|
          config.home_dir = paths_config['home_dir'] if paths_config.key?('home_dir')
          config.restic_mount_point = paths_config['restic_mount_point'] if paths_config.key?('restic_mount_point')
          config.restic_repo = paths_config['restic_repo'] if paths_config.key?('restic_repo')
        end

        instance
      end

      def validate_paths
        validate_home_dir
        validate_restic_mount_point
        validate_restic_repo
      end

      def validate_home_dir
        expanded_path = File.expand_path(config.home_dir)
        return if File.directory?(expanded_path)

        raise ArgumentError, "Home directory does not exist: #{expanded_path}"
      end

      def validate_restic_mount_point
        mount_point = File.expand_path(config.restic_mount_point)
        parent_dir = File.dirname(mount_point)

        return if File.directory?(parent_dir)

        raise ArgumentError, "Parent directory for restic mount point does not exist: #{parent_dir}"
      end

      def validate_restic_repo
        return unless config.restic_repo.nil? || config.restic_repo.empty?

        raise ArgumentError, "Restic repository path must be specified"
      end

      def validate!
        validate_paths
      end

      def expanded_home_dir
        File.expand_path(config.home_dir)
      end

      def expanded_restic_mount_point
        File.expand_path(config.restic_mount_point)
      end

      def ensure_restic_mount_point
        mount_point = expanded_restic_mount_point
        FileUtils.mkdir_p(mount_point) unless File.directory?(mount_point)
        mount_point
      end
    end
  end
end