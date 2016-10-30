module Birdwatcher
  module Commands
    class Spool < Birdwatcher::Command
      self.meta = {
        :description => "Write console output into a file as well the screen",
        :names       => %w(spool),
        :usage       => "spool FILE|off"
      }

      def self.detailed_usage
<<-USAGE
The #{'spool'.bold} command can be used to write all console output into a file
as well the screen. The output will be appended to the file if it already exists.

#{'USAGE:'.bold}

#{'Spool output to a file:'.bold}
  spool FILE

#{'Turn off spooling:'.bold}
  spool off

#{'See status of spooling:'.bold}
  spool status
USAGE
      end

      def run
        if !arguments?
          error("You must provide a path to a file or an action")
          return false
        end
        action = arguments.first.downcase
        case action
        when "start"
          start_spooling
        when "off", "stop"
          stop_spooling
        when "status"
          status_spooling
        else
          start_spooling
        end
      end

      private

      def start_spooling
        if arguments.first.downcase == "start"
          file = arguments[1, -1].join(" ")
        else
          file = arguments.join(" ")
        end
        if file.empty?
          error("You must provide a path to a file")
          return false
        end
        console.spool = File.open(file, "a").tap { |f| f.sync = true }
        info("Spooling output to #{file.bold}")
      end

      def stop_spooling
        console.spool = nil
        info("Output spooling stopped")
      end

      def status_spooling
        if console.spool && console.spool.is_a?(File)
          info("Spooling output to #{console.spool.path.bold}")
        else
          info("Output spooling is stopped")
        end
      end
    end
  end
end
