# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComputerTools::Interfaces::Validation do
  describe '.implements_git_interface?' do
    let(:git_wrapper) { ComputerTools::Wrappers::GitWrapper.new }
    let(:non_git_object) { Object.new }

    it 'returns true for objects implementing GitInterface' do
      expect(described_class.implements_git_interface?(git_wrapper)).to be true
    end

    it 'returns false for objects not implementing GitInterface' do
      expect(described_class.implements_git_interface?(non_git_object)).to be false
    end
  end

  describe '.implements_backup_interface?' do
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
    let(:non_backup_object) { Object.new }

    it 'returns true for objects implementing BackupInterface' do
      expect(described_class.implements_backup_interface?(restic_wrapper)).to be true
    end

    it 'returns false for objects not implementing BackupInterface' do
      expect(described_class.implements_backup_interface?(non_backup_object)).to be false
    end
  end

  describe '.implements_database_interface?' do
    let(:blueprint_database) { ComputerTools::Wrappers::BlueprintDatabase.new }
    let(:non_database_object) { Object.new }

    it 'returns true for objects implementing DatabaseInterface' do
      expect(described_class.implements_database_interface?(blueprint_database)).to be true
    end

    it 'returns false for objects not implementing DatabaseInterface' do
      expect(described_class.implements_database_interface?(non_database_object)).to be false
    end
  end

  describe '.validate_di_compatibility' do
    let(:git_wrapper) { ComputerTools::Wrappers::GitWrapper.new }
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
    let(:non_interface_object) { Object.new }

    context 'with valid git interface implementation' do
      let(:result) { described_class.validate_di_compatibility(git_wrapper, :git) }

      it 'returns valid result' do
        expect(result[:valid]).to be true
      end

      it 'indicates interface is implemented' do
        expect(result[:interface_implemented]).to be true
      end

      it 'has no errors' do
        expect(result[:errors]).to be_empty
      end

      it 'may have warnings about constructor' do
        expect(result[:warnings]).to be_an(Array)
      end
    end

    context 'with valid backup interface implementation' do
      let(:result) { described_class.validate_di_compatibility(restic_wrapper, :backup) }

      it 'returns valid result for interface implementation' do
        expect(result[:interface_implemented]).to be true
      end

      it 'has warnings about required constructor parameters' do
        expect(result[:warnings]).to include(/Constructor has required parameters/)
      end
    end

    context 'with invalid interface implementation' do
      let(:result) { described_class.validate_di_compatibility(non_interface_object, :git) }

      it 'returns invalid result' do
        expect(result[:valid]).to be false
      end

      it 'indicates interface is not implemented' do
        expect(result[:interface_implemented]).to be false
      end

      it 'has errors about interface implementation' do
        expect(result[:errors]).to include(/Object does not implement git interface/)
      end
    end

    context 'with unknown interface type' do
      let(:result) { described_class.validate_di_compatibility(git_wrapper, :unknown) }

      it 'returns invalid result' do
        expect(result[:valid]).to be false
      end

      it 'has errors about unknown interface type' do
        expect(result[:errors]).to include(/Unknown interface type: unknown/)
      end
    end
  end

  describe '.implements_interface_module?' do
    let(:git_wrapper) { ComputerTools::Wrappers::GitWrapper.new }
    let(:non_git_object) { Object.new }

    it 'returns true when object implements the interface module' do
      expect(described_class.implements_interface_module?(git_wrapper, ComputerTools::Interfaces::GitInterface)).to be true
    end

    it 'returns false when object does not implement the interface module' do
      expect(described_class.implements_interface_module?(non_git_object, ComputerTools::Interfaces::GitInterface)).to be false
    end
  end

  describe 'private method .implements_interface?' do
    let(:object_with_methods) do
      Class.new do
        def method_a; end
        def method_b; end
        def method_c; end
      end.new
    end
    
    let(:object_without_methods) { Object.new }

    it 'returns true when object has all required methods' do
      required_methods = [:method_a, :method_b, :method_c]
      expect(described_class.send(:implements_interface?, object_with_methods, required_methods)).to be true
    end

    it 'returns false when object is missing required methods' do
      required_methods = [:method_a, :method_b, :method_d]
      expect(described_class.send(:implements_interface?, object_with_methods, required_methods)).to be false
    end

    it 'returns false when object has no required methods' do
      required_methods = [:method_a, :method_b, :method_c]
      expect(described_class.send(:implements_interface?, object_without_methods, required_methods)).to be false
    end
  end
end