module Birdwatcher
  module Commands
    class Resource < Birdwatcher::Command
      self.meta = {
        :description => "Execute commands from a resource file",
        :names       => %w(resource),
        :usage       => "resource FILE"
      }

      def self.detailed_usage
<<-USAGE
The #{'resource'.bold} command can be used to execute commands from a file on disk.
Resource files are simple text-based files containing one command per line. They
can be very convenient for common or repetitive workflows.

#{'USAGE:'.bold}

#{'Execute commands from a resource file:'.bold}
  resource <FILE>
USAGE
      end

      def run
        if !arguments?
          error("You must provide a path to a resource file")
          return false
        end
        filepath = File.expand_path(arguments.join(" "))
        if !File.exists?(filepath)
          error("File #{filepath.bold} does not exist")
          return false
        end
        if !File.readable?(filepath)
          error("File #{filepath} is not readable")
          return false
        end
        File.read(filepath).each_line do |command|
          command.strip!
          next if command.empty? || command.start_with?("#") || command.start_with?("//")
          console.handle_input(command.strip)
        end
      end
    end
  end
end
