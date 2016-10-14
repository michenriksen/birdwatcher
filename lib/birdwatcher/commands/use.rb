module Birdwatcher
  module Commands
    class Use < Birdwatcher::Command
      self.meta = {
        :description => "Load specified module",
        :names       => %w(use load),
        :usage       => "use MODULE_PATH"
      }

      def run
        if !arguments?
          error("You must provide a module path")
          return false
        end

        if !_module = Birdwatcher::Module.module_by_path(arguments.first)
          error("Unknown module: #{arguments.first.bold}")
          return false
        end

        console.current_module = _module
      end
    end
  end
end
