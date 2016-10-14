module Birdwatcher
  module Commands
    class Shell < Birdwatcher::Command
      self.meta = {
        :description => "Execute shell command",
        :names       => %w(shell),
        :usage       => "shell COMMAND"
      }

      def run
        if !arguments?
          error("You must provide a shell command to execute")
          return false
        end

        command = arguments.join(" ")
        output `#{command}`
      end
    end
  end
end
