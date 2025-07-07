#!/usr/bin/env ruby

# Temporary script to update namespaces in reorganized generator files
require 'fileutils'

def update_generator_file(file_path, new_namespace)
  content = File.read(file_path)
  
  # Update the module structure
  content.gsub!(/module ComputerTools\s+module Generators\s+class/, "module ComputerTools\n  module Generators\n    module #{new_namespace}\n      class")
  
  # Add missing closing end for new namespace
  content.gsub!(/^  end\s+end\s*$/, "    end\n  end\nend")
  
  # Make sure we have proper closing
  unless content.match(/end\s*$/)
    content += "\nend"
  end
  
  File.write(file_path, content)
  puts "Updated #{file_path} with #{new_namespace} namespace"
end

# Update blueprint generators
blueprint_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/generators/blueprints/*.rb']
blueprint_files.each do |file|
  update_generator_file(file, 'Blueprints')
end

# Update deepgram generators
deepgram_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/generators/deepgram/*.rb']
deepgram_files.each do |file|
  update_generator_file(file, 'Deepgram')
end

# Update system generators
system_files = Dir['/home/b08x/Workspace/ComputerTools/lib/ComputerTools/generators/system/*.rb']
system_files.each do |file|
  update_generator_file(file, 'System')
end

puts "All generator files updated!"