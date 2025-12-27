# frozen_string_literal: true

require 'dry-container'

module ComputerTools
  ##
  # ComputerTools::Container manages dependency injection for the application using dry-container.
  #
  # This container provides centralized registration and resolution of dependencies, enabling
  # better testability and loose coupling between components.
  #
  # @example Basic usage
  #   ComputerTools::Container.register('logger') { Logger.new }
  #   logger = ComputerTools::Container['logger']
  #
  # @example Using with dependency injection
  #   action = ComputerTools::Container['example_action']
  #   action.execute
  module Container
    extend Dry::Container::Mixin

    # Register basic dependencies that are needed application-wide
    register 'configuration' do
      ComputerTools::Configuration.new
    end

    register 'logger' do
      ComputerTools::Logger.instance
    end

    ##
    # Load additional registrations from the registrations file
    #
    # This method is called during application initialization to set up
    # all the dependency registrations for the application.
    #
    # @return [void]
    def self.load_registrations
      require_relative 'container/registrations'
    end

    ##
    # Register a dependency with lazy loading
    #
    # @param name [String] The dependency name
    # @param block [Proc] The block that creates the dependency
    # @return [void]
    #
    # @example
    #   ComputerTools::Container.register_lazy('expensive_service') do
    #     ExpensiveService.new
    #   end
    def self.register_lazy(name, &block)
      register(name, memoize: true, &block)
    end

    ##
    # Register a dependency as a singleton
    #
    # @param name [String] The dependency name
    # @param instance [Object] The singleton instance
    # @return [void]
    #
    # @example
    #   ComputerTools::Container.register_singleton('cache', Cache.new)
    def self.register_singleton(name, instance)
      register(name) { instance }
    end

    ##
    # Check if a dependency is registered
    #
    # @param name [String] The dependency name
    # @return [Boolean] true if registered, false otherwise
    #
    # @example
    #   ComputerTools::Container.registered?('logger') # => true
    def self.registered?(name)
      key?(name)
    end

    ##
    # Resolve a dependency with error handling
    #
    # @param name [String] The dependency name
    # @return [Object] The resolved dependency
    # @raise [StandardError] if dependency cannot be resolved
    #
    # @example
    #   logger = ComputerTools::Container.resolve_dependency('logger')
    def self.resolve_dependency(name)
      self[name]
    rescue Dry::Container::KeyError => e
      raise StandardError, "Failed to resolve dependency '#{name}': #{e.message}"
    end
  end
end