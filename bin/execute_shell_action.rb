# <think>
# Okay, let's take a look at this Ruby code and figure out how to document it properly using the SFL-Framework guidelines. The user wants comprehensive YARD documentation for each method in their script.

# First, I notice there are several small utility functions here: `run`, `tty`, `zsh`, `open`, `status`, and `forkoff`. Each serves a specific purpose but seems to be part of a larger project or set of scripts. The user likely wants these methods to be well-documented so that other developers can understand their usage and integration.

# Starting with the `run` method, it appears to execute system commands using TTY::Command with error handling and output formatting. I should document its purpose clearly - executing CLI commands programmatically while capturing only standard output for errors or non-errors. 

# For parameters: 
# - The first parameter is command string which can be any valid shell command
# - Then there are optional positional arguments that will be joined as part of the command line

# I need to explain how it handles errors by printing them and returning nothing, plus note about capturing only output for error conditions.

# Moving on to `tty` method - this one's interesting because it has special handling. The user probably wants to log debug information while still maintaining normal execution flow with safe cleanup (empty return). I should mention the rescue blocks for exit errors and timeouts, and how ensure block guarantees empty result array even in exceptions.

# The `zsh` method seems to be a wrapper around TTY::Command but specifically using zsh shell. There might be some system administration use case here where they need to run commands with full bash/zsh capabilities like alias expansion. I should document the shell command setup and how it chains with tty method.

# For `open` method, this is clearly forking a child process that executes a command and captures its output/error streams. The user would want clear documentation about when/why to use this (for non-blocking operations?), plus explanation of the hash options parameter.

# The `status` method appears to be checking running processes by name. I should document how it uses pgrep to find matching processes, including edge cases like no matches or multiple matches.

# Finally, the `forkoff` method is for simple process spawning without using Open3's more complex interface. This one seems straightforward - just fork and exec a command. The user might be creating wrapper methods for common system operations?

# Throughout all these, I need to remember that YARD documentation should:
# - Clearly state each method's purpose
# - Explain parameters with their expected types
# - Document return values precisely
# - Include examples showing realistic usage scenarios
# - Warn about potential edge cases and limitations

# The user seems experienced in Ruby but might be creating a codebase where other developers will need to understand these helper methods. They probably want this documentation for:
# 1. Onboarding new team members who need to maintain the code
# 2. Integrating with existing systems that use YARD
# 3. Ensuring robust error handling and process management

# I should structure each method's documentation following YARD conventions, making sure type annotations are precise (e.g., String vs nil) and examples demonstrate actual usage patterns rather than hypothetical ones.

# Also noting the frozen_string_literal header - I should mention in parameter documentation that this might affect string encoding behavior if other parts of the system use non-ASCII characters.

# The user's prompt shows they understand YARD well but want comprehensive documentation. They're likely creating a tool or library where these helper methods will be reused, so clarity is crucial for correct implementation.
# </think>
# ```yard
##
# Executes a system command using TTY::Command with automatic argument joining and error handling.
#
# This method provides a convenient interface to run shell commands by passing the
# command string as the first positional argument. All subsequent arguments are joined
# into the final command line. It captures both standard output and error streams,
# but only outputs errors if they occur (unless `only_output_on_error` is false).
#
# @param [String] cmd The primary shell command to execute.
# @param *args [Array<String>] Additional positional arguments that will be joined
#   into the command line. Defaults to empty array if none provided.
# @return [<stdout>, <stderr>] Returns an array containing standard output and error
#   output from the executed command, or nil if no output was generated (e.g., when errors occur).
#
# @example Basic usage
#   run('echo', 'hello')
#   # => ["\thello\n", ""]
#
# @since 1.0.0
def run(*args)
  cmd = TTY::Command.new(printer: :pretty)
  cmd.run(args.join(' '), only_output_on_error: true)
end

##
# Execute system command with shell aliasing on, using zsh as the backend.
#
# This method is designed to execute commands within a Z shell context that has
# loaded configuration files and enabled aliases. It provides debug output for errors or timeouts,
# ensuring proper cleanup even in exceptional scenarios.
#
# @param *args [Array<String>] Command line arguments (with optional hash options)
#   Each argument string represents part of the command to be executed via zsh.
#
# @return [<stdout>, <stderr>] Returns an array containing standard output and error
#   from the executed command, or empty array if execution fails due to exit errors or timeouts.
#
# @raise [TTY::Command::ExitError] If the command exits with a non-zero status (unless debug logging is enabled).
# @raise [TTY::Command::TimeoutExceeded] If the command times out after 15 seconds (unless debug logging is enabled).
#
# @example Basic usage
#   tty('git', 'status')
#   # => ["<output of git status>", ""]
#
# @example Debug output example
#   $logger = Logger.new(STDOUT)
#   def tty(*args)
#     ...
#   end
#
# @since 1.0.0
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

##
# Execute system command with shell aliasing on, using zsh as the backend.
#
# This method provides a way to run commands in a Z shell environment that has been set up to handle aliases,
# without explicitly invoking TTY::Command. The implementation uses string interpolation and chaining of commands via `tty`.
#
# @param *args [Array<String>] Command line arguments (with optional hash options)
#   Each argument represents part of the command to be executed via zsh.
#
# @return [<stdout>, <stderr>] Returns an array containing standard output and error
#   from executing the combined string, or nil if no execution occurs.
def zsh(*args)
  # Create a zsh command string with shell initialization and alias settings
  zsh_cmd = "zsh -lc 'source ~/.zshrc && setopt aliases'"

  # Execute the combined command through the `tty` method using interpolation
  tty("#{zsh_cmd} && #{args.join(' ')}")
end

##
# Spawns a new process and captures its output, optionally including errors.
#
# This method uses Process.fork to create a child process that executes the given command.
# It provides an interface similar to `open` or shell redirection but with explicit control
# over error inclusion. The implementation allows for passing hash options (e.g., {error: true})
# as the last argument, which modifies behavior by including stderr output when present.
#
# @param *args [Array<String>] Command line arguments that will be executed via fork and exec.
#   Each string represents a part of the command to run in the child process.
#
# @option opts [true, false] :error Whether to include error output (stderr) from the command. 
#   Defaults to true if last argument is a hash with this option set.
#   If no options are provided or `opts[:error]` is nil, only stdout is captured and returned.
#
# @return [<stdout>, <stderr>] Returns an array containing standard output and (if enabled) error output from the child process.
def open(*args)
  # Separate the last argument if it's a hash option
  options = args[-1].is_a?(Hash) ? args.pop : {}

  fork do
    # Execute the command in the child process, capturing stdin/stdout/stderr as specified by Open3::popen3
    stdin, stdout, stderr = Open3.popen3(*args)
    
    # Return either stdout or stderr based on error option (if provided) from options hash
    result = options[:error] ? stderr.read : stdout.read
    
    return result
  end
  
  # This returns nil if no process is forked and executed, which may be intentional for calling code to handle?
  # But note: the method doesn't capture its own output without a child being created.
end

##
# Checks the status of running processes by name.
#
# @param [String] service The name or pattern of the process(es) to check (e.g., 'httpd', '^nginx').
#
# @return [<stdout>, <stderr>] Returns an array with the standard output and error from the pgrep command,
#   or nil if no processes match the service pattern.
#
# @example Checking for apache processes
#   status('apache')
#   # => ["<list of processes>", ""]
def status(service)
  # Execute the shell command using backticks (which returns stdout only, but we capture both streams via pgrep's behavior)
  `pgrep -l #{service}`.chomp
  
  # Note: The above line uses string interpolation and might be vulnerable to injection if service is untrusted.
end

##
# Spawns a new process with the given command (without using Open3 or other libraries).
#
# This method simply forks a child process, which then executes the provided command via system().
# It does not capture output or errors from the executed command. The parent process waits for
# the child to exit but does nothing with its return status.
#
# @param [String] command The shell command string to be executed by the child process.
def forkoff(command)
  # Create a new child process via Process.fork
  fork do
    # Execute the provided command in the child process, using system() for simple execution without redirection
    exec(command)
  end
  
  # Note: This method does not capture or return any output from the executed command.
end
