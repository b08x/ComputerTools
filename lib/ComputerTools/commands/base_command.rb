module ComputerTools
  module Commands
    class BaseCommand
      def self.command_name
        name.split("::").last.gsub(/Command$/, '').downcase
      end

      def self.description
        "Description for #{command_name}"
      end

      def initialize(options)
        @options = options
      end

      def execute(*args)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      protected

      # Logger convenience methods for easy migration
      def logger
        ComputerTools.logger
      end

      def log_success(message, **data)
        ComputerTools.logger.success(message, **data)
      end

      def log_failure(message, **data)
        ComputerTools.logger.failure(message, **data)
      end

      def log_warning(message, **data)
        ComputerTools.logger.warn(message, **data)
      end

      def log_tip(message, **data)
        ComputerTools.logger.tip(message, **data)
      end

      def log_step(message, **data)
        ComputerTools.logger.step(message, **data)
      end

      def log_info(message, **data)
        ComputerTools.logger.info(message, **data)
      end

      def log_debug(message, **data)
        ComputerTools.logger.debug(message, **data)
      end

      def log_error(message, **data)
        ComputerTools.logger.error(message, **data)
      end
    end
  end
end
