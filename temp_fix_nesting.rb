#!/usr/bin/env ruby

# Fix module nesting in command files
require 'fileutils'

def fix_command_nesting(file_path, expected_namespace)
  content = File.read(file_path)

  # Check if the file already has the correct nesting
  if content.include?("module #{expected_namespace}")
    puts "#{file_path} already has correct nesting"
    return
  end

  # Find the class definition line
  class_match = content.match(/^(\s*)(class \w+Command.*)/m)
  if class_match
    indent = class_match[1]
    class_def = class_match[2]

    # Replace the class definition with properly nested version
    new_class_def = "#{indent}module #{expected_namespace}\n#{indent}  #{class_def}"
    content.gsub!(class_match[0], new_class_def)

    # Add extra closing end for the new module
    # Find the last closing ends and add one more
    content.gsub!(/^(\s*)end\s*$/, '\1end')
    content += "\n#{indent}end" unless content.strip.end_with?("end\nend")

    File.write(file_path, content)
    puts "Fixed nesting in #{file_path}"
  else
    puts "Could not find class definition in #{file_path}"
  end
end

# Map directories to their expected namespace modules
namespace_map = {
  'content_management' => 'ContentManagement',
  'media_processing' => 'MediaProcessing',
  'analysis' => 'Analysis',
  'interface' => 'Interface'
}

namespace_map.each do |dir, namespace|
  command_files = Dir["/home/b08x/Workspace/ComputerTools/lib/computertools/commands/#{dir}/*.rb"]
  command_files.each do |file|
    next if file.end_with?('.rb') && File.basename(file, '.rb') == dir # Skip namespace files

    fix_command_nesting(file, namespace)
  end
end

puts "All command file nesting fixed!"