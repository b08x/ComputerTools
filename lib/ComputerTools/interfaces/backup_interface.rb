# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # BackupInterface defines the contract for backup and restore operations.
    #
    # This interface specifies the methods that any backup wrapper implementation
    # must provide for mounting, unmounting, and comparing files with backup snapshots.
    #
    # @example Implementing the interface
    #   class MyBackupWrapper
    #     include ComputerTools::Interfaces::BackupInterface
    #
    #     def mount_backup
    #       # Implementation here
    #     end
    #
    #     # ... other interface methods
    #   end
    module BackupInterface
      ##
      # Ensures the backup repository is mounted and accessible.
      #
      # @abstract
      # @return [Boolean] true if the backup is mounted or was successfully mounted, false otherwise
      # @raise [NotImplementedError] if not implemented
      def ensure_mounted
        raise NotImplementedError, "#{self.class} must implement #ensure_mounted"
      end

      ##
      # Checks if the backup repository is currently mounted.
      #
      # @abstract
      # @return [Boolean] true if the backup is mounted, false otherwise
      # @raise [NotImplementedError] if not implemented
      def mounted?
        raise NotImplementedError, "#{self.class} must implement #mounted?"
      end

      ##
      # Mounts the backup repository.
      #
      # @abstract
      # @return [Boolean] true if the backup was successfully mounted, false otherwise
      # @raise [NotImplementedError] if not implemented
      def mount_backup
        raise NotImplementedError, "#{self.class} must implement #mount_backup"
      end

      ##
      # Unmounts the backup repository.
      #
      # @abstract
      # @return [void]
      # @raise [NotImplementedError] if not implemented
      def unmount
        raise NotImplementedError, "#{self.class} must implement #unmount"
      end

      ##
      # Returns the path to the latest snapshot in the backup.
      #
      # @abstract
      # @return [String] The path to the latest snapshot
      # @raise [NotImplementedError] if not implemented
      def snapshot_path
        raise NotImplementedError, "#{self.class} must implement #snapshot_path"
      end

      ##
      # Compares a current file with its version in the backup snapshot.
      #
      # @abstract
      # @param current_file [String] The path to the current file
      # @param snapshot_file [String] The path to the file in the snapshot
      # @return [Hash] A hash containing comparison results with keys:
      #   - :exists_in_current [Boolean] - whether file exists in current location
      #   - :exists_in_snapshot [Boolean] - whether file exists in snapshot
      #   - :identical [Boolean] - whether files are identical
      #   - :differences [String, nil] - description of differences if any
      # @raise [NotImplementedError] if not implemented
      def compare_with_snapshot(current_file, snapshot_file)
        raise NotImplementedError, "#{self.class} must implement #compare_with_snapshot"
      end

      ##
      # Performs cleanup operations for the backup wrapper.
      #
      # This method should unmount any mounted resources and clean up
      # any temporary files or processes.
      #
      # @abstract
      # @return [void]
      # @raise [NotImplementedError] if not implemented
      def cleanup
        raise NotImplementedError, "#{self.class} must implement #cleanup"
      end

      ##
      # Gets the mount point where the backup repository is mounted.
      #
      # @abstract
      # @return [String] The mount point path
      # @raise [NotImplementedError] if not implemented
      def mount_point
        raise NotImplementedError, "#{self.class} must implement #mount_point"
      end

      ##
      # Gets the backup repository location.
      #
      # @abstract
      # @return [String] The repository path or URL
      # @raise [NotImplementedError] if not implemented
      def repository
        raise NotImplementedError, "#{self.class} must implement #repository"
      end
    end
  end
end