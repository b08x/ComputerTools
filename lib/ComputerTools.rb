require "yaml"
require "thor"
require "sublayer"
require_relative "ComputerTools/version"
require_relative "ComputerTools/config"

Dir[File.join(__dir__, "ComputerTools", "commands", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "ComputerTools", "agents", "*.rb")].each { |file| require file }

require_relative "ComputerTools/cli"

module ComputerTools
  class Error < StandardError; end
  Config.load

  def self.root
    File.dirname __dir__
  end
end
