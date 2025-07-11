# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Interfaces::BackupInterface do
  let(:dummy_class) do
    Class.new do
      include ComputerTools::Interfaces::BackupInterface
    end
  end
  
  let(:instance) { dummy_class.new }

  describe 'interface contract' do
    it 'defines all required methods' do
      required_methods = [
        :ensure_mounted, :mounted?, :mount_backup, :unmount, :snapshot_path,
        :compare_with_snapshot, :cleanup, :mount_point, :repository
      ]
      
      required_methods.each do |method|
        expect(instance).to respond_to(method)
      end
    end

    it 'raises NotImplementedError for unimplemented methods' do
      expect { instance.ensure_mounted }.to raise_error(NotImplementedError)
      expect { instance.mounted? }.to raise_error(NotImplementedError)
      expect { instance.mount_backup }.to raise_error(NotImplementedError)
      expect { instance.unmount }.to raise_error(NotImplementedError)
      expect { instance.snapshot_path }.to raise_error(NotImplementedError)
      expect { instance.compare_with_snapshot('file1', 'file2') }.to raise_error(NotImplementedError)
      expect { instance.cleanup }.to raise_error(NotImplementedError)
      expect { instance.mount_point }.to raise_error(NotImplementedError)
      expect { instance.repository }.to raise_error(NotImplementedError)
    end
  end

  describe 'ResticWrapper implementation' do
    let(:config) do
      double('config').tap do |config|
        allow(config).to receive(:fetch).with(:paths, :restic_mount_point).and_return('/tmp/test_mount')
        allow(config).to receive(:fetch).with(:paths, :restic_repo).and_return('/tmp/test_repo')
        allow(config).to receive(:fetch).with(:paths, :home_dir).and_return('/tmp/test_home')
        allow(config).to receive(:fetch).with(:restic, :mount_timeout).and_return(60)
        allow(config).to receive(:fetch).with(:terminal, :command).and_return('bash')
        allow(config).to receive(:fetch).with(:terminal, :args).and_return('-c')
      end
    end
    
    let(:restic_wrapper) { ComputerTools::Wrappers::ResticWrapper.new(config) }

    it 'implements the BackupInterface' do
      expect(restic_wrapper).to be_a(ComputerTools::Interfaces::BackupInterface)
    end

    it 'implements all required methods' do
      expect(ComputerTools::Interfaces::Validation.implements_backup_interface?(restic_wrapper)).to be true
    end

    it 'responds to all interface methods' do
      expect(restic_wrapper).to respond_to(:ensure_mounted)
      expect(restic_wrapper).to respond_to(:mounted?)
      expect(restic_wrapper).to respond_to(:mount_backup)
      expect(restic_wrapper).to respond_to(:unmount)
      expect(restic_wrapper).to respond_to(:snapshot_path)
      expect(restic_wrapper).to respond_to(:compare_with_snapshot)
      expect(restic_wrapper).to respond_to(:cleanup)
      expect(restic_wrapper).to respond_to(:mount_point)
      expect(restic_wrapper).to respond_to(:repository)
    end

    it 'has dependency injection compatibility' do
      result = ComputerTools::Interfaces::Validation.validate_di_compatibility(restic_wrapper, :backup)
      expect(result[:interface_implemented]).to be true
      expect(result[:warnings]).to include(/Constructor has required parameters/)
    end
  end

  describe 'method signatures' do
    let(:implemented_class) do
      Class.new do
        include ComputerTools::Interfaces::BackupInterface
        
        def ensure_mounted; end
        def mounted?; end
        def mount_backup; end
        def unmount; end
        def snapshot_path; end
        def compare_with_snapshot(current_file, snapshot_file); end
        def cleanup; end
        def mount_point; end
        def repository; end
      end
    end
    
    let(:implemented_instance) { implemented_class.new }

    it 'accepts correct parameters for each method' do
      expect { implemented_instance.ensure_mounted }.not_to raise_error
      expect { implemented_instance.mounted? }.not_to raise_error
      expect { implemented_instance.mount_backup }.not_to raise_error
      expect { implemented_instance.unmount }.not_to raise_error
      expect { implemented_instance.snapshot_path }.not_to raise_error
      expect { implemented_instance.compare_with_snapshot('file1', 'file2') }.not_to raise_error
      expect { implemented_instance.cleanup }.not_to raise_error
      expect { implemented_instance.mount_point }.not_to raise_error
      expect { implemented_instance.repository }.not_to raise_error
    end
  end
end