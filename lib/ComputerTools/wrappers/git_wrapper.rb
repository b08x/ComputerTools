# frozen_string_literal: true

require 'git'

module ComputerTools
  module Wrappers
    class GitWrapper
      def initialize
        @repositories = {}
      end

      def open_repository(path)
        return @repositories[path] if @repositories[path]

        begin
          @repositories[path] = Git.open(path)
        rescue Git::Error => e
          puts "⚠️  Warning: Could not open Git repository at #{path}: #{e.message}".colorize(:yellow)
          nil
        end
      end

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

      def get_file_diff(git, file_path)
        # For untracked files, we can't diff against HEAD
        if git.status.untracked.include?(file_path)
          return { additions: 0, deletions: 0, chunks: 0 }
        end

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

      def repository_exists?(path)
        File.directory?(File.join(path, '.git'))
      end

      def find_repository_root(file_path)
        dir = File.dirname(file_path)

        while dir != '/'
          return dir if repository_exists?(dir)

          dir = File.dirname(dir)
        end

        nil
      end

      def file_tracked?(git, file_path)
        !git.status.untracked.include?(file_path)
      rescue Git::Error
        false
      end

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

      def get_branch_name(git)
        git.current_branch
      rescue Git::Error
        'unknown'
      end

      def is_dirty?(git)
        !git.status.changed.empty? || !git.status.added.empty? || !git.status.deleted.empty?
      rescue Git::Error
        false
      end

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