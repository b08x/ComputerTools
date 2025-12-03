module ComputerTools
  module Actions
    class ZshellHistoryAction < Sublayer::Actions::Base
      def initialize
        @zsh_cmd = "zsh -lc 'source ~/.zshrc && setopt aliases'"
        @args = ['history -i 1']
      end
      end

      def call
        tty("#{@zsh_cmd} && #{@args.join(' ')}")
      end

      private

      def tty(*args)
        cmd = TTY::Command.new(output: $logger, uuid: false, timeout: 15)

        begin
          out, err = cmd.run(args.join(' '), only_output_on_error: true)
        rescue TTY::Command::ExitError => e
          $logger.debug "#{e} #{args}"
          exit
        rescue TTY:"Command":TimeoutExceeded => e
          $logger.debug "#{e} #{args}"
        ensure
          results = out
        end


      end


    end
  end
end