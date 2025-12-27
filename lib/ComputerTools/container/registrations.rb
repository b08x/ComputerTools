# frozen_string_literal: true

module ComputerTools
  module Container
    ##
    # This module contains all dependency registrations for the ComputerTools application.
    #
    # Registrations are organized by category to maintain clarity and separation of concerns.
    # Each registration should be documented with its purpose and dependencies.
    module Registrations
      ##
      # Register all dependencies for the application
      #
      # This method is called during application initialization to set up
      # all the required dependencies in the container. It registers core dependencies,
      # wrappers, actions, generators, and configurations.
      #
      # @return [void]
      def self.register_all
        register_core_dependencies
        register_wrappers
        register_actions
        register_generators
        register_configurations
      end

      ##
      # Register core application dependencies
      #
      # These are fundamental dependencies that are used throughout the application.
      # Currently, it's assumed that the logger and configuration are already registered
      # in the main container file.  This method provides a placeholder for registering
      # other core dependencies as needed.
      #
      # @return [void]
      # @example
      #   # Example registration of an event bus
      #   ComputerTools::Container.register('event_bus') do
      #     EventBus.new
      #   end
      def self.register_core_dependencies
        # Logger is already registered in the main container file
        # Configuration is already registered in the main container file

        # Register other core dependencies here as needed
        # Example:
        # ComputerTools::Container.register('event_bus') do
        #   EventBus.new
        # end
      end

      ##
      # Register wrapper dependencies
      #
      # Wrapper classes provide interfaces to external tools and services.  This method registers
      # wrappers for Git, Restic, Docling, Trafilatura, DeepgramParser,
      # DeepgramAnalyzer, and DeepgramFormatter.
      #
      # @return [void]
      def self.register_wrappers
        # Git wrapper for version control operations
        ComputerTools::Container.register('git_wrapper') do
          ComputerTools::Wrappers::GitWrapper.new
        end

        # Restic wrapper for backup operations
        ComputerTools::Container.register('restic_wrapper') do
          ComputerTools::Wrappers::ResticWrapper.new(
            ComputerTools::Container['configuration']
          )
        end

        # Docling wrapper for document processing
        ComputerTools::Container.register('docling_wrapper') do
          ComputerTools::Wrappers::Docling.new
        end

        # Trafilatura wrapper for web content extraction
        ComputerTools::Container.register('trafilatura_wrapper') do
          ComputerTools::Wrappers::Trafilatura.new
        end

        # Deepgram-related wrappers
        ComputerTools::Container.register('deepgram_parser') do
          ComputerTools::Wrappers::DeepgramParser.new
        end

        ComputerTools::Container.register('deepgram_analyzer') do
          ComputerTools::Wrappers::DeepgramAnalyzer.new
        end

        ComputerTools::Container.register('deepgram_formatter') do
          ComputerTools::Wrappers::DeepgramFormatter.new
        end
      end

      ##
      # Register action dependencies
      #
      # Action classes encapsulate business logic and coordinate between components. This method
      # registers various actions related to, deepgram, and file activity.
      #
      # @return [void]
      def self.register_actions
        # Deepgram actions
        ComputerTools::Container.register('deepgram_parse_action') do
          ComputerTools::Actions::Deepgram::DeepgramParseAction.new(
            parser: ComputerTools::Container['deepgram_parser']
          )
        end

        ComputerTools::Container.register('deepgram_analyze_action') do
          ComputerTools::Actions::Deepgram::DeepgramAnalyzeAction.new(
            analyzer: ComputerTools::Container['deepgram_analyzer']
          )
        end

        ComputerTools::Container.register('deepgram_convert_action') do
          ComputerTools::Actions::Deepgram::DeepgramConvertAction.new(
            formatter: ComputerTools::Container['deepgram_formatter']
          )
        end

        ComputerTools::Container.register('deepgram_config_action') do
          ComputerTools::Actions::Deepgram::DeepgramConfigAction.new
        end

        # File activity actions
        ComputerTools::Container.register('git_analysis_action') do
          ComputerTools::Actions::FileActivity::GitAnalysisAction.new(
            git_wrapper: ComputerTools::Container['git_wrapper']
          )
        end

        ComputerTools::Container.register('restic_analysis_action') do
          ComputerTools::Actions::FileActivity::ResticAnalysisAction.new(
            restic_wrapper: ComputerTools::Container['restic_wrapper']
          )
        end

        ComputerTools::Container.register('yadm_analysis_action') do
          ComputerTools::Actions::FileActivity::YadmAnalysisAction.new
        end

        ComputerTools::Container.register('file_discovery_action') do
          ComputerTools::Actions::FileActivity::FileDiscoveryAction.new
        end

        ComputerTools::Container.register('latest_changes_action') do
          ComputerTools::Actions::FileActivity::LatestChangesAction.new
        end

        # Example action
        ComputerTools::Container.register('example_action') do
          ComputerTools::Actions::ExampleAction.new
        end

        # Shell command action
        ComputerTools::Container.register('run_shell_command') do
          ComputerTools::Actions::RunShellCommand.new
        end

        # Mount restic repository action
        ComputerTools::Container.register('mount_restic_repo_action') do
          ComputerTools::Actions::MountResticRepoAction.new
        end
      end

      def self.register_generators
        # Deepgram generators
        ComputerTools::Container.register('deepgram_summary_generator') do
          ComputerTools::Generators::Deepgram::DeepgramSummaryGenerator.new
        end

        ComputerTools::Container.register('deepgram_topics_generator') do
          ComputerTools::Generators::Deepgram::DeepgramTopicsGenerator.new
        end

        ComputerTools::Container.register('deepgram_insights_generator') do
          ComputerTools::Generators::Deepgram::DeepgramInsightsGenerator.new
        end

        # File activity generators
        ComputerTools::Container.register('file_activity_report_generator') do
          ComputerTools::Generators::FileActivity::FileActivityReportGenerator.new
        end

        # Overview generator
        ComputerTools::Container.register('overview_generator') do
          ComputerTools::Generators::OverviewGenerator.new
        end
      end

      ##
      # Register configuration dependencies
      #
      # Configuration objects provide typed access to application settings. This method registers
      # configurations for logging, paths, terminal, display, backup, and application settings.
      # It also ensures backward compatibility by registering the 'configuration' key if it's not
      # already registered.
      #
      # @return [void]
      def self.register_configurations
        # Load YAML data for configurations
        yaml_data = ComputerTools::Configurations::ConfigurationFactory.load_yaml_data

        # Register individual configuration objects
        ComputerTools::Container.register('logging_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_logging_config(yaml_data)
        end

        ComputerTools::Container.register('path_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_path_config(yaml_data)
        end

        ComputerTools::Container.register('terminal_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_terminal_config(yaml_data)
        end

        ComputerTools::Container.register('display_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_display_config(yaml_data)
        end

        ComputerTools::Container.register('backup_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_backup_config(yaml_data)
        end

        ComputerTools::Container.register('application_configuration') do
          ComputerTools::Configurations::ConfigurationFactory.create_application_config
        end

        # Backward compatibility - maintain existing registration
        return if ComputerTools::Container.registered?('configuration')

        ComputerTools::Container.register('configuration') do
          ComputerTools::Container['application_configuration']
        end
      end
    end
  end
end