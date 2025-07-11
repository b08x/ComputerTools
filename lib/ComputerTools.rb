#!/usr/bin/env ruby
lib_dir = File.expand_path(File.join(__dir__, "..", "lib"))
$:.unshift lib_dir unless $LOAD_PATH.include?(lib_dir)

require "bundler/setup"
require "tty-config"
require "tty-prompt"
require "tty-which"
require "tty-command"
require "fileutils"
require "time"
require "yaml"
require "thor"
require "sublayer"
require "colorize"
require_relative "ComputerTools/version"
require_relative "ComputerTools/config"
require_relative "ComputerTools/logger"

Dir[File.join(__dir__, 'ComputerTools', 'providers', '*.rb')].sort.each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "wrappers", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "commands", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "agents", "*.rb")].each { |file| require file }

require_relative "ComputerTools/cli"

module ComputerTools
  class Error < StandardError; end
  Config.load

  # Provides global access to the logger instance
  def self.logger
    ComputerTools::Logger.instance
  end

  def self.root
    File.dirname __dir__
  end
end
