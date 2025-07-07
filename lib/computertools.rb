#!/usr/bin/env ruby
# frozen_string_literal: true

lib_dir = File.expand_path(File.join(__dir__, "..", "computertools"))
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include?(lib_dir)

require "yaml"
require "thor"
require "sublayer"
require "colorize"
require "zeitwerk"
require "tty-prompt"

require 'computertools/actions/blueprints/blueprint_list'

module ComputerTools
  # Configure Zeitwerk autoloader
  @loader = Zeitwerk::Loader.new
  @loader.push_dir(File.expand_path('computertools', __dir__), namespace: ComputerTools)
  @loader.inflector.inflect(
    "cli" => "CLI"
  )
  # Ignore files that don't follow the class naming convention
  @loader.ignore(File.expand_path('computertools/version.rb', __dir__))
  @loader.ignore(File.expand_path('computertools/config.rb', __dir__))
  @loader.setup

  def self.loader
    @loader
  end
end

require "computertools/version"
require "computertools/config"
require "computertools/cli"

module ComputerTools
  class Error < StandardError; end
  Config.load

  def self.root
    File.dirname __dir__
  end
end
