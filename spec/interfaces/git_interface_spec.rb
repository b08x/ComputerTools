# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Interfaces::GitInterface do
  let(:dummy_class) do
    Class.new do
      include ComputerTools::Interfaces::GitInterface
    end
  end
  
  let(:instance) { dummy_class.new }

  describe 'interface contract' do
    it 'defines all required methods' do
      required_methods = [
        :open_repository, :get_file_status, :get_file_diff, :repository_exists?,
        :find_repository_root, :file_tracked?, :get_recent_commits, :get_branch_name,
        :is_dirty?, :get_uncommitted_changes_count
      ]
      
      required_methods.each do |method|
        expect(instance).to respond_to(method)
      end
    end

    it 'raises NotImplementedError for unimplemented methods' do
      expect { instance.open_repository('/path') }.to raise_error(NotImplementedError)
      expect { instance.get_file_status(nil, 'file') }.to raise_error(NotImplementedError)
      expect { instance.get_file_diff(nil, 'file') }.to raise_error(NotImplementedError)
      expect { instance.repository_exists?('/path') }.to raise_error(NotImplementedError)
      expect { instance.find_repository_root('/path/file') }.to raise_error(NotImplementedError)
      expect { instance.file_tracked?(nil, 'file') }.to raise_error(NotImplementedError)
      expect { instance.get_recent_commits(nil) }.to raise_error(NotImplementedError)
      expect { instance.get_branch_name(nil) }.to raise_error(NotImplementedError)
      expect { instance.is_dirty?(nil) }.to raise_error(NotImplementedError)
      expect { instance.get_uncommitted_changes_count(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe 'GitWrapper implementation' do
    let(:git_wrapper) { ComputerTools::Wrappers::GitWrapper.new }

    it 'implements the GitInterface' do
      expect(git_wrapper).to be_a(ComputerTools::Interfaces::GitInterface)
    end

    it 'implements all required methods' do
      expect(ComputerTools::Interfaces::Validation.implements_git_interface?(git_wrapper)).to be true
    end

    it 'responds to all interface methods' do
      expect(git_wrapper).to respond_to(:open_repository)
      expect(git_wrapper).to respond_to(:get_file_status)
      expect(git_wrapper).to respond_to(:get_file_diff)
      expect(git_wrapper).to respond_to(:repository_exists?)
      expect(git_wrapper).to respond_to(:find_repository_root)
      expect(git_wrapper).to respond_to(:file_tracked?)
      expect(git_wrapper).to respond_to(:get_recent_commits)
      expect(git_wrapper).to respond_to(:get_branch_name)
      expect(git_wrapper).to respond_to(:is_dirty?)
      expect(git_wrapper).to respond_to(:get_uncommitted_changes_count)
    end

    it 'has dependency injection compatibility' do
      result = ComputerTools::Interfaces::Validation.validate_di_compatibility(git_wrapper, :git)
      expect(result[:valid]).to be true
      expect(result[:interface_implemented]).to be true
      expect(result[:errors]).to be_empty
    end
  end

  describe 'method signatures' do
    let(:implemented_class) do
      Class.new do
        include ComputerTools::Interfaces::GitInterface
        
        def open_repository(path); end
        def get_file_status(git, file_path); end
        def get_file_diff(git, file_path); end
        def repository_exists?(path); end
        def find_repository_root(file_path); end
        def file_tracked?(git, file_path); end
        def get_recent_commits(git, limit: 10); end
        def get_branch_name(git); end
        def is_dirty?(git); end
        def get_uncommitted_changes_count(git); end
      end
    end
    
    let(:implemented_instance) { implemented_class.new }

    it 'accepts correct parameters for each method' do
      expect { implemented_instance.open_repository('/path') }.not_to raise_error
      expect { implemented_instance.get_file_status(nil, 'file') }.not_to raise_error
      expect { implemented_instance.get_file_diff(nil, 'file') }.not_to raise_error
      expect { implemented_instance.repository_exists?('/path') }.not_to raise_error
      expect { implemented_instance.find_repository_root('/path/file') }.not_to raise_error
      expect { implemented_instance.file_tracked?(nil, 'file') }.not_to raise_error
      expect { implemented_instance.get_recent_commits(nil) }.not_to raise_error
      expect { implemented_instance.get_recent_commits(nil, limit: 5) }.not_to raise_error
      expect { implemented_instance.get_branch_name(nil) }.not_to raise_error
      expect { implemented_instance.is_dirty?(nil) }.not_to raise_error
      expect { implemented_instance.get_uncommitted_changes_count(nil) }.not_to raise_error
    end
  end
end