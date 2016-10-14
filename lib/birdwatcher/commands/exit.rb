module Birdwatcher
  module Commands
    class Exit < Birdwatcher::Command
      self.meta = {
        :description => "Exit Birdwatcher",
        :names       => %w(exit quit q),
        :usage       => "exit"
      }

      def run
        output "Goodbye."
        exit
      end
    end
  end
end
