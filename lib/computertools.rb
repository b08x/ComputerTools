require "yaml"
require "thor"
require "sublayer"
require "colorize"
require "zeitwerk"
require "tty-prompt"

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

require_relative "computertools/version"
require_relative "computertools/config"
require_relative "computertools/cli"

module ComputerTools
  class Error < StandardError; end
  Config.load

  def self.root
    File.dirname __dir__
  end
end
