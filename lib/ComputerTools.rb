#!/usr/bin/env ruby
lib_dir = File.expand_path(File.join(__dir__, "..", "lib"))
$:.unshift lib_dir unless $:.include?(lib_dir)

require 'colorize'
require 'fileutils'
require 'git'
require 'json'
require 'net/http'
require 'open3'
require 'pg'
require 'sequel'
require 'sublayer'
require 'tempfile'
require 'terrapin'
require 'thor'
require 'time'
require 'tty-command'
require 'tty-config'
require 'tty-file'
require 'tty-logger'
require 'tty-prompt'
require 'tty-table'
require 'tty-which'
require 'uri'
require 'yaml'

require "ComputerTools/version"
require "ComputerTools/config"
require "ComputerTools/logger"
require "ComputerTools/configuration"
require "ComputerTools/container"

# Load role-specific configuration classes
require "ComputerTools/configuration/logging_configuration"
require "ComputerTools/configuration/path_configuration"
require "ComputerTools/configuration/terminal_configuration"
require "ComputerTools/configuration/display_configuration"
require "ComputerTools/configuration/backup_configuration"
require "ComputerTools/configuration/configuration_factory"
require "ComputerTools/configuration/application_configuration"

# Load interfaces
require "ComputerTools/interfaces/git_interface"
require "ComputerTools/interfaces/backup_interface"
require "ComputerTools/interfaces/database_interface"
require "ComputerTools/interfaces/processor_interface"
require "ComputerTools/interfaces/configurable_interface"
require "ComputerTools/interfaces/parser_interface"
require "ComputerTools/interfaces/formatter_interface"
require "ComputerTools/interfaces/validation"

require "ComputerTools/providers/sublayer/ollama"
require "ComputerTools/providers/sublayer/openrouter"

require "ComputerTools/actions/blueprint/blueprint_config_action"
require "ComputerTools/actions/blueprint/blueprint_edit_action"
require "ComputerTools/actions/blueprint/blueprint_list_action"
require "ComputerTools/actions/blueprint/blueprint_search_action"
require "ComputerTools/actions/blueprint/blueprint_delete_action"
require "ComputerTools/actions/blueprint/blueprint_export_action"
require "ComputerTools/actions/blueprint/blueprint_submit_action"
require "ComputerTools/actions/blueprint/blueprint_view_action"

require "ComputerTools/actions/deepgram/deepgram_analyze_action"
require "ComputerTools/actions/deepgram/deepgram_config_action"
require "ComputerTools/actions/deepgram/deepgram_convert_action"
require "ComputerTools/actions/deepgram/deepgram_parse_action"

require "ComputerTools/actions/file_activity/file_discovery_action"
require "ComputerTools/actions/file_activity/git_analysis_action"
require "ComputerTools/actions/file_activity/latest_changes_action"
require "ComputerTools/actions/file_activity/restic_analysis_action"
require "ComputerTools/actions/file_activity/yadm_analysis_action"

require "ComputerTools/wrappers/blueprint_database"
require "ComputerTools/wrappers/deepgram_analyzer"
require "ComputerTools/wrappers/deepgram_formatter"
require "ComputerTools/wrappers/deepgram_parser"
require "ComputerTools/wrappers/docling"
require "ComputerTools/wrappers/git_wrapper"
require "ComputerTools/wrappers/restic_wrapper"
require "ComputerTools/wrappers/trafilatura"

require "ComputerTools/commands/base_command"
require "ComputerTools/commands/menu_command"
require "ComputerTools/commands/blueprint_command"
require "ComputerTools/commands/config_command"
require "ComputerTools/commands/deepgram_command"
require "ComputerTools/commands/latest_changes_command"
require "ComputerTools/commands/overview_command"

require 'ComputerTools/generators/blueprint/blueprint_category_generator'
require 'ComputerTools/generators/blueprint/blueprint_description_generator'
require 'ComputerTools/generators/blueprint/blueprint_improvement_generator'
require 'ComputerTools/generators/blueprint/blueprint_name_generator'

require "ComputerTools/generators/deepgram/deepgram_insights_generator"
require "ComputerTools/generators/deepgram/deepgram_summary_generator"
require "ComputerTools/generators/deepgram/deepgram_topics_generator"

require "ComputerTools/generators/file_activity/file_activity_report_generator"

require "ComputerTools/generators/overview_generator"

Dir[File.join(__dir__, "ComputerTools", "agents", "*.rb")].each { |file| require file }

require_relative "ComputerTools/cli"

module ComputerTools
  class Error < StandardError; end
  Config.load

  # Provides global access to the logger instance
  def self.logger
    ComputerTools::Logger.instance
  end

  # Provides global access to the dependency injection container
  def self.container
    @container ||= ComputerTools::Container
  end

  # Initialize the container with all registrations
  def self.initialize_container
    ComputerTools::Container.load_registrations
    ComputerTools::Container::Registrations.register_all
    container
  end

  def self.root
    File.dirname __dir__
  end
end
