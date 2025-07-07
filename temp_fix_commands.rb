#!/usr/bin/env ruby

# Fix command files to use proper namespaces and requires
require 'fileutils'

def fix_command_file(file_path)
  content = File.read(file_path)

  # Fix inheritance to use Interface::BaseCommand
  content.gsub!('< BaseCommand', '< Interface::BaseCommand')

  # Fix any base_command requires
  content.gsub!(/require_relative ['"]base_command['"]/, "require_relative '../interface/base_command'")

  # Fix configuration requires
  content.gsub!(%r{require_relative ['"]\.\./configuration['"]}, "require_relative '../../configuration'")

  File.write(file_path, content)
  puts "Fixed #{file_path}"
end

# Fix all command files
command_files = Dir['/home/b08x/Workspace/ComputerTools/lib/computertools/commands/**/*.rb']
command_files.reject! { |f| f.include?('interface/') } # Skip interface files themselves

command_files.each do |file|
  fix_command_file(file)
end

puts "All command files fixed!"