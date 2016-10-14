module Birdwatcher
  module Commands
    class Run < Birdwatcher::Command
      self.meta = {
        :description => "Run current module",
        :names       => %w(run execute),
        :usage       => "run"
      }

      def run
        if !console.current_module
          error("No module loaded")
          return false
        end
        console.current_module.new.execute
      end
    end
  end
end
