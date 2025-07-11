# frozen_string_literal: true

module ComputerTools
  module Wrappers
    # GitWrapper provides a comprehensive interface for interacting with Git repositories.
    # It handles common Git operations while managing repository connections and providing
    # detailed information about file statuses, differences, and repository state.
    #
    # This wrapper is particularly useful for applications that need to analyze or monitor
    # Git repositories, providing a consistent interface that handles errors gracefully.
    #
    # @example Basic usage
    #   wrapper = ComputerTools::Wrappers::GitWrapper.new
    #   git = wrapper.open_repository('/path/to/repo')
    #   status = wrapper.get_file_status(git, 'file.txt')
    class GitWrapper
      # Initializes a new GitWrapper instance with an empty repository cache.
      #
      # @return [GitWrapper] a new instance of GitWrapper
      def initialize
        @repositories = {}
      end

      # Opens a Git repository at the specified path, caching the connection for future use.
      #
      # This method maintains a repository cache to avoid repeatedly opening the same repository,
      # which improves performance when working with multiple files in the same repository.
      #
      # @param path [String] the path to the Git repository
      # @return [Git, nil] the Git repository object if successful, nil if the repository couldn't be opened
      # @example Opening a repository
      #   wrapper = ComputerTools::Wrappers::GitWrapper.new
      #   git = wrapper.open_repository('/path/to/repo')
      def open_repository(path)
        return @repositories[path] if @repositories[path]

        begin
          @repositories[path] = Git.open(path)
        rescue Git::Error => e
          puts "⚠️  Warning: Could not open Git repository at #{path}: #{e.message}".colorize(:yellow)
          nil
        end
      end

      # Retrieves the status of a file in the Git repository.
      #
      # This method provides detailed information about a file's status in both the index
      # (staging area) and the working tree, which is useful for determining what changes
      # have been made to a file.
      #
      # @param git [Git] the Git repository object
      # @param file_path [String] the path to the file relative to the repository root
      # @return [Hash] a hash containing the file status information with keys:
      #   :raw_status - the raw status string from Git
      #   :index - the status in the index (staging area)
      #   :worktree - the status in the working tree
      # @example Getting file status
      #   status = wrapper.get_file_status(git, 'file.txt')
      #   # => { raw_status: ' M', index: 'Unchanged', worktree: 'Modified' }
      def get_file_status(git, file_path)
        git_status = git.status

        if git_status.added.include?(file_path)
          { raw_status: 'A ', index: 'Added', worktree: 'Unchanged' }
        elsif git_status.changed.include?(file_path)
          { raw_status: ' M', index: 'Unchanged', worktree: 'Modified' }
        elsif git_status.deleted.include?(file_path)
          { raw_status: ' D', index: 'Unchanged', worktree: 'Deleted' }
        elsif git_status.untracked.include?(file_path)
          { raw_status: '??', index: 'Unchanged', worktree: 'Untracked' }
        else
          { raw_status: '--', index: 'Clean', worktree: 'Clean' }
        end
      rescue Git::Error => e
        puts "⚠️  Warning: Could not get status for #{file_path}: #{e.message}".colorize(:yellow)
        { raw_status: '--', index: 'Error', worktree: 'Error' }
      end

      # Retrieves the diff information for a file in the Git repository.
      #
      # This method provides statistics about the changes made to a file, which is useful
      # for understanding the scope of modifications. Note that untracked files will always
      # return zero values since they can't be diffed against HEAD.
      #
      # @param git [Git] the Git repository object
      # @param file_path [String] the path to the file relative to the repository root
      # @return [Hash] a hash containing the diff information with keys:
      #   :additions - the number of lines added
      #   :deletions - the number of lines deleted
      #   :chunks - the number of change chunks
      # @example Getting file diff
      #   diff = wrapper.get_file_diff(git, 'file.txt')
      #   # => { additions: 5, deletions: 2, chunks: 1 }
      def get_file_diff(git, file_path)
        # For untracked files, we can't diff against HEAD
        return { additions: 0, deletions: 0, chunks: 0 } if git.status.untracked.include?(file_path)

        diff = git.diff('HEAD', file_path)

        if diff.size > 0
          file_diff = diff.first
          {
            additions: file_diff.patch ? file_diff.patch.scan(/^\+[^+]/).length : 0,
            deletions: file_diff.patch ? file_diff.patch.scan(/^-[^-]/).length : 0,
            chunks: file_diff.patch ? file_diff.patch.scan(/^@@/).length : 0
          }
        else
          { additions: 0, deletions: 0, chunks: 0 }
        end
      rescue Git::Error => e
        puts "⚠️  Warning: Could not get diff for #{file_path}: #{e.message}".colorize(:yellow) if ENV['DEBUG']
        { additions: 0, deletions: 0, chunks: 0 }
      end

      # Checks if a Git repository exists at the specified path.
      #
      # @param path [String] the path to check for a Git repository
      # @return [Boolean] true if a Git repository exists at the path, false otherwise
      # @example Checking for a repository
      #   exists = wrapper.repository_exists?('/path/to/repo')
      def repository_exists?(path)
        File.directory?(File.join(path, '.git'))
      end

      # Finds the root directory of the Git repository containing the specified file.
      #
      # This method walks up the directory tree starting from the file's location
      # until it finds a directory containing a .git folder.
      #
      # @param file_path [String] the path to a file in the repository
      # @return [String, nil] the path to the repository root if found, nil otherwise
      # @example Finding repository root
      #   root = wrapper.find_repository_root('/path/to/repo/file.txt')
      #   # => '/path/to/repo'
      def find_repository_root(file_path)
        dir = File.dirname(file_path)

        while dir != '/'
          return dir if repository_exists?(dir)

          dir = File.dirname(dir)
        end

        nil
      end

      # Checks if a file is tracked in the Git repository.
      #
      # @param git [Git] the Git repository object
      # @param file_path [String] the path to the file relative to the repository root
      # @return [Boolean] true if the file is tracked, false otherwise
      # @example Checking if a file is tracked
      #   tracked = wrapper.file_tracked?(git, 'file.txt')
      def file_tracked?(git, file_path)
        !git.status.untracked.include?(file_path)
      rescue Git::Error
        false
      end

      # Retrieves recent commits from the Git repository.
      #
      # @param git [Git] the Git repository object
      # @param limit [Integer] the maximum number of commits to retrieve (default: 10)
      # @return [Array<Hash>] an array of commit hashes, each containing:
      #   :sha - the commit SHA
      #   :message - the commit message
      #   :author - the author's name
      #   :date - the commit date
      # @example Getting recent commits
      #   commits = wrapper.get_recent_commits(git, limit: 5)
      def get_recent_commits(git, limit: 10)
        git.log(limit).map do |commit|
          {
            sha: commit.sha,
            message: commit.message,
            author: commit.author.name,
            date: commit.date
          }
        end
      rescue Git::Error => e
        puts "⚠️  Warning: Could not get recent commits: #{e.message}".colorize(:yellow)
        []
      end

      # Gets the current branch name of the Git repository.
      #
      # @param git [Git] the Git repository object
      # @return [String] the name of the current branch, or 'unknown' if it couldn't be determined
      # @example Getting the current branch
      #   branch = wrapper.get_branch_name(git)
      def get_branch_name(git)
        git.current_branch
      rescue Git::Error
        'unknown'
      end

      # Checks if the Git repository has uncommitted changes.
      #
      # A repository is considered "dirty" if it has modified, added, or deleted files.
      #
      # @param git [Git] the Git repository object
      # @return [Boolean] true if the repository has uncommitted changes, false otherwise
      # @example Checking if a repository is dirty
      #   dirty = wrapper.is_dirty?(git)
      def is_dirty?(git)
        !git.status.changed.empty? || !git.status.added.empty? || !git.status.deleted.empty?
      rescue Git::Error
        false
      end

      # Gets counts of uncommitted changes in the Git repository.
      #
      # @param git [Git] the Git repository object
      # @return [Hash] a hash containing counts of different types of changes with keys:
      #   :modified - number of modified files
      #   :added - number of added files
      #   :deleted - number of deleted files
      #   :untracked - number of untracked files
      # @example Getting uncommitted changes count
      #   changes = wrapper.get_uncommitted_changes_count(git)
      #   # => { modified: 2, added: 1, deleted: 0, untracked: 3 }
      def get_uncommitted_changes_count(git)
        status = git.status
        {
          modified: status.changed.count,
          added: status.added.count,
          deleted: status.deleted.count,
          untracked: status.untracked.count
        }
      rescue Git::Error
        { modified: 0, added: 0, deleted: 0, untracked: 0 }
      end
    end
  end
end