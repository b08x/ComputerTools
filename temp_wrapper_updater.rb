#!/usr/bin/env ruby

# Temporary script to update namespaces in reorganized wrapper files
require 'fileutils'

def update_wrapper_file(file_path, new_namespace)
  content = File.read(file_path)
  
  # Update the module structure
  content.gsub!(/module ComputerTools\s+module Wrappers\s+class/, "module ComputerTools\n  module Wrappers\n    module #{new_namespace}\n      class")
  
  # Add missing closing end for new namespace
  content.gsub!(/^  end\s+end\s*$/, "    end\n  end\nend")
  
  # Make sure we have proper closing
  unless content.match(/end\s*$/)
    content += "\nend"
  end
  
  File.write(file_path, content)
  puts "Updated #{file_path} with #{new_namespace} namespace"
end

# Update audio wrappers
audio_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/wrappers/audio/*.rb']
audio_files.each do |file|
  update_wrapper_file(file, 'Audio')
end

# Update documents wrappers
documents_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/wrappers/documents/*.rb']
documents_files.each do |file|
  update_wrapper_file(file, 'Documents')
end

# Update version control wrappers
version_control_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/wrappers/version_control/*.rb']
version_control_files.each do |file|
  update_wrapper_file(file, 'VersionControl')
end

# Update backup wrappers
backup_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/wrappers/backup/*.rb']
backup_files.each do |file|
  update_wrapper_file(file, 'Backup')
end

# Update database wrappers
database_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/wrappers/database/*.rb']
database_files.each do |file|
  update_wrapper_file(file, 'Database')
end

puts "All wrapper files updated!"