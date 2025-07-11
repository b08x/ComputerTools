# frozen_string_literal: true

module ComputerTools
  module Interfaces
    ##
    # Validation provides utilities for validating interface implementations.
    #
    # This module contains helper methods to verify that objects properly
    # implement the required interface contracts for dependency injection.
    module Validation
      ##
      # Validates that an object implements the GitInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements GitInterface, false otherwise
      # @example
      #   git_wrapper = GitWrapper.new
      #   Validation.implements_git_interface?(git_wrapper) # => true
      def self.implements_git_interface?(object)
        required_methods = [
          :open_repository, :get_file_status, :get_file_diff, :repository_exists?,
          :find_repository_root, :file_tracked?, :get_recent_commits, :get_branch_name,
          :is_dirty?, :get_uncommitted_changes_count
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the BackupInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements BackupInterface, false otherwise
      # @example
      #   restic_wrapper = ResticWrapper.new(config)
      #   Validation.implements_backup_interface?(restic_wrapper) # => true
      def self.implements_backup_interface?(object)
        required_methods = [
          :ensure_mounted, :mounted?, :mount_backup, :unmount, :snapshot_path,
          :compare_with_snapshot, :cleanup, :mount_point, :repository
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the DatabaseInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements DatabaseInterface, false otherwise
      # @example
      #   database = BlueprintDatabase.new
      #   Validation.implements_database_interface?(database) # => true
      def self.implements_database_interface?(object)
        required_methods = [
          :create_record, :get_record, :update_record, :delete_record,
          :list_records, :search_records, :stats, :connection
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the ProcessorInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements ProcessorInterface, false otherwise
      # @example
      #   processor = DocumentProcessor.new
      #   Validation.implements_processor_interface?(processor) # => true
      def self.implements_processor_interface?(object)
        required_methods = [
          :process, :can_process?, :supported_input_formats, :supported_output_formats
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the ConfigurableInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements ConfigurableInterface, false otherwise
      # @example
      #   configurable = DoclingWrapper.new
      #   Validation.implements_configurable_interface?(configurable) # => true
      def self.implements_configurable_interface?(object)
        required_methods = [
          :configure, :run, :reset, :valid?, :to_hash
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the ParserInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements ParserInterface, false otherwise
      # @example
      #   parser = DeepgramParser.new('file.json')
      #   Validation.implements_parser_interface?(parser) # => true
      def self.implements_parser_interface?(object)
        required_methods = [
          :parse_data, :extract_fields, :available_fields, :valid_format?,
          :summary_stats, :raw_data
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements the FormatterInterface.
      #
      # @param object [Object] The object to validate
      # @return [Boolean] true if object implements FormatterInterface, false otherwise
      # @example
      #   formatter = DeepgramFormatter.new(parser)
      #   Validation.implements_formatter_interface?(formatter) # => true
      def self.implements_formatter_interface?(object)
        required_methods = [
          :format_data, :to_json, :to_markdown, :supported_formats,
          :supports_format?, :default_format
        ]
        
        implements_interface?(object, required_methods)
      end

      ##
      # Validates that an object implements all methods in the interface.
      #
      # @param object [Object] The object to validate
      # @param interface_module [Module] The interface module to check against
      # @return [Boolean] true if object implements all interface methods, false otherwise
      # @example
      #   git_wrapper = GitWrapper.new
      #   Validation.implements_interface_module?(git_wrapper, GitInterface) # => true
      def self.implements_interface_module?(object, interface_module)
        interface_methods = interface_module.instance_methods(false)
        implements_interface?(object, interface_methods)
      end

      ##
      # Validates dependency injection compatibility for a wrapper object.
      #
      # Checks that the object can be safely used in dependency injection
      # by validating its interface implementation and constructor compatibility.
      #
      # @param object [Object] The object to validate
      # @param expected_interface [Symbol] The expected interface type (:git, :backup, :database, etc.)
      # @return [Hash] Validation result with :valid, :errors, and :warnings keys
      # @example
      #   result = Validation.validate_di_compatibility(git_wrapper, :git)
      #   puts "Valid: #{result[:valid]}"
      #   puts "Errors: #{result[:errors]}"
      def self.validate_di_compatibility(object, expected_interface)
        errors = []
        warnings = []
        
        # Check interface implementation
        interface_valid = case expected_interface
        when :git
          implements_git_interface?(object)
        when :backup
          implements_backup_interface?(object)
        when :database
          implements_database_interface?(object)
        when :processor
          implements_processor_interface?(object)
        when :configurable
          implements_configurable_interface?(object)
        when :parser
          implements_parser_interface?(object)
        when :formatter
          implements_formatter_interface?(object)
        else
          errors << "Unknown interface type: #{expected_interface}"
          false
        end
        
        errors << "Object does not implement #{expected_interface} interface" unless interface_valid
        
        # Check for dependency injection friendly constructor
        constructor_params = object.class.instance_method(:initialize).parameters
        if constructor_params.any? { |type, _| type == :req }
          warnings << "Constructor has required parameters, may need container configuration"
        end
        
        {
          valid: errors.empty?,
          errors: errors,
          warnings: warnings,
          interface_implemented: interface_valid
        }
      end

      private

      ##
      # Helper method to check if an object implements a list of required methods.
      #
      # @param object [Object] The object to check
      # @param required_methods [Array<Symbol>] The methods that must be implemented
      # @return [Boolean] true if all methods are implemented, false otherwise
      def self.implements_interface?(object, required_methods)
        required_methods.all? { |method| object.respond_to?(method) }
      end
    end
  end
end