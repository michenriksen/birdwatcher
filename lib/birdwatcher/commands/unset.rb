module Birdwatcher
  module Commands
    class Unset < Birdwatcher::Command
      self.meta = {
        :description => "Unset module option",
        :names       => %w(unset),
        :usage       => "unset OPTION"
      }

      def run
        if !arguments?
          error("You must provide an option name")
          return false
        end

        if !current_module
          error("No module loaded")
          return false
        end

        option = arguments.first.upcase
        if !current_module.meta[:options].keys.include?(option)
          error("Unknown option: #{option.bold}")
          return false
        end

        current_module.meta[:options][option][:value] = nil
      end

      private

      def current_module
        console.current_module
      end
    end
  end
end
