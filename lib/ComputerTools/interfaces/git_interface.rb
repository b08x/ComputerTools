# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # GitInterface defines the contract for Git repository operations.
    #
    # This interface specifies the methods that any Git wrapper implementation
    # must provide for repository management, file status checking, and change tracking.
    #
    # @example Implementing the interface
    #   class MyGitWrapper
    #     include ComputerTools::Interfaces::GitInterface
    #
    #     def open_repository(path)
    #       # Implementation here
    #     end
    #
    #     # ... other interface methods
    #   end
    module GitInterface
      ##
      # Opens a Git repository at the specified path.
      #
      # @abstract
      # @param path [String] The path to the Git repository
      # @return [Object, nil] The Git repository object if successful, nil otherwise
      # @raise [NotImplementedError] if not implemented
      def open_repository(path)
        raise NotImplementedError, "#{self.class} must implement #open_repository"
      end

      ##
      # Retrieves the status of a file in the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @param file_path [String] The path to the file relative to the repository root
      # @return [Hash] A hash containing file status information with keys:
      #   - :raw_status [String] - the raw status string from Git
      #   - :index [String] - the status in the index (staging area)
      #   - :worktree [String] - the status in the working tree
      # @raise [NotImplementedError] if not implemented
      def get_file_status(git, file_path)
        raise NotImplementedError, "#{self.class} must implement #get_file_status"
      end

      ##
      # Retrieves the diff information for a file in the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @param file_path [String] The path to the file relative to the repository root
      # @return [Hash] A hash containing diff information with keys:
      #   - :additions [Integer] - the number of lines added
      #   - :deletions [Integer] - the number of lines deleted
      #   - :chunks [Integer] - the number of change chunks
      # @raise [NotImplementedError] if not implemented
      def get_file_diff(git, file_path)
        raise NotImplementedError, "#{self.class} must implement #get_file_diff"
      end

      ##
      # Checks if a Git repository exists at the specified path.
      #
      # @abstract
      # @param path [String] The path to check for a Git repository
      # @return [Boolean] true if a Git repository exists at the path, false otherwise
      # @raise [NotImplementedError] if not implemented
      def repository_exists?(path)
        raise NotImplementedError, "#{self.class} must implement #repository_exists?"
      end

      ##
      # Finds the root directory of the Git repository containing the specified file.
      #
      # @abstract
      # @param file_path [String] The path to a file in the repository
      # @return [String, nil] The path to the repository root if found, nil otherwise
      # @raise [NotImplementedError] if not implemented
      def find_repository_root(file_path)
        raise NotImplementedError, "#{self.class} must implement #find_repository_root"
      end

      ##
      # Checks if a file is tracked in the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @param file_path [String] The path to the file relative to the repository root
      # @return [Boolean] true if the file is tracked, false otherwise
      # @raise [NotImplementedError] if not implemented
      def file_tracked?(git, file_path)
        raise NotImplementedError, "#{self.class} must implement #file_tracked?"
      end

      ##
      # Retrieves recent commits from the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @param limit [Integer] The maximum number of commits to retrieve
      # @return [Array<Hash>] An array of commit hashes, each containing:
      #   - :sha [String] - the commit SHA
      #   - :message [String] - the commit message
      #   - :author [String] - the author's name
      #   - :date [Time] - the commit date
      # @raise [NotImplementedError] if not implemented
      def get_recent_commits(git, limit: 10)
        raise NotImplementedError, "#{self.class} must implement #get_recent_commits"
      end

      ##
      # Gets the current branch name of the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @return [String] The name of the current branch
      # @raise [NotImplementedError] if not implemented
      def get_branch_name(git)
        raise NotImplementedError, "#{self.class} must implement #get_branch_name"
      end

      ##
      # Checks if the Git repository has uncommitted changes.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @return [Boolean] true if the repository has uncommitted changes, false otherwise
      # @raise [NotImplementedError] if not implemented
      def is_dirty?(git)
        raise NotImplementedError, "#{self.class} must implement #is_dirty?"
      end

      ##
      # Gets counts of uncommitted changes in the Git repository.
      #
      # @abstract
      # @param git [Object] The Git repository object
      # @return [Hash] A hash containing counts of different types of changes with keys:
      #   - :modified [Integer] - number of modified files
      #   - :added [Integer] - number of added files
      #   - :deleted [Integer] - number of deleted files
      #   - :untracked [Integer] - number of untracked files
      # @raise [NotImplementedError] if not implemented
      def get_uncommitted_changes_count(git)
        raise NotImplementedError, "#{self.class} must implement #get_uncommitted_changes_count"
      end
    end
  end
end