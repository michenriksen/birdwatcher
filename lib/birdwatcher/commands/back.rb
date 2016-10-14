module Birdwatcher
  module Commands
    class Back < Birdwatcher::Command
      self.meta = {
        :description => "Unloads current module",
        :names       => %w(back unload),
        :usage       => "back"
      }

      def run
        console.current_module = nil
      end
    end
  end
end
