#!/usr/bin/env ruby

# Temporary script to update namespaces in reorganized files
require 'fileutils'

def update_action_file(file_path, new_namespace)
  content = File.read(file_path)
  
  # Update the module structure
  content.gsub!(/module ComputerTools\s+module Actions\s+class/, "module ComputerTools\n  module Actions\n    module #{new_namespace}\n      class")
  
  # Fix CONFIG_PATH if present
  if content.include?("CONFIG_PATH = File.join(__dir__, '..', 'config'")
    content.gsub!(/CONFIG_PATH = File\.join\(__dir__, '\.\.', 'config'/, "CONFIG_PATH = File.join(__dir__, '..', '..', 'config'")
  end
  
  # Add missing closing end for new namespace
  content.gsub!(/^    end\s+end\s+end\s*$/, "    end\n  end\nend")
  content.gsub!(/^    end\s+end\s*$/, "    end\n  end\nend")
  
  # Make sure we have proper closing
  unless content.match(/end\s*$/)
    content += "\nend"
  end
  
  File.write(file_path, content)
  puts "Updated #{file_path} with #{new_namespace} namespace"
end

# Update blueprint actions
blueprint_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/actions/blueprints/*.rb']
blueprint_files.each do |file|
  update_action_file(file, 'Blueprints')
end

# Update deepgram actions
deepgram_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/actions/deepgram/*.rb']
deepgram_files.each do |file|
  update_action_file(file, 'Deepgram')
end

# Update version control actions
version_control_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/actions/version_control/*.rb']
version_control_files.each do |file|
  update_action_file(file, 'VersionControl')
end

# Update utilities actions
utilities_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/actions/utilities/*.rb']
utilities_files.each do |file|
  update_action_file(file, 'Utilities')
end

puts "All action files updated!"