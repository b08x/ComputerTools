#!/usr/bin/env ruby

# Temporary script to update namespaces in reorganized command files
require 'fileutils'

def update_command_file(file_path, new_namespace)
  content = File.read(file_path)
  
  # Update the module structure
  content.gsub!(/module ComputerTools\s+module Commands\s+class/, "module ComputerTools\n  module Commands\n    module #{new_namespace}\n      class")
  
  # Add missing closing end for new namespace
  content.gsub!(/^  end\s+end\s*$/, "    end\n  end\nend")
  
  # Make sure we have proper closing
  unless content.match(/end\s*$/)
    content += "\nend"
  end
  
  File.write(file_path, content)
  puts "Updated #{file_path} with #{new_namespace} namespace"
end

# Update content management commands
content_management_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/commands/content_management/*.rb']
content_management_files.each do |file|
  update_command_file(file, 'ContentManagement')
end

# Update media processing commands
media_processing_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/commands/media_processing/*.rb']
media_processing_files.each do |file|
  update_command_file(file, 'MediaProcessing')
end

# Update analysis commands
analysis_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/commands/analysis/*.rb']
analysis_files.each do |file|
  update_command_file(file, 'Analysis')
end

# Update interface commands
interface_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/commands/interface/*.rb']
interface_files.each do |file|
  update_command_file(file, 'Interface')
end

puts "All command files updated!"