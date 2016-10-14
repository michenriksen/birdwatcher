module Birdwatcher
  module Commands
    class Set < Birdwatcher::Command
      self.meta = {
        :description => "Set module option",
        :names       => %w(set),
        :usage       => "set OPTION VALUE"
      }

      TRUTHY_VALUES = %w(1 true yes on).freeze
      FALSY_VALUES  = %w(0 false no off).freeze

      def run
        if arguments.count < 2
          error("You must provide an option name and value")
          return false
        end

        if !current_module
          error("No module loaded")
          return false
        end

        option, value = arguments.first.upcase, arguments[1..-1].join(" ")
        if !current_module.meta[:options].keys.include?(option)
          error("Unknown option: #{option.bold}")
          return false
        end

        if current_module.meta[:options][option][:boolean]
          if truthy?(value)
            value = true
          elsif falsy?(value)
            value = false
          end
        end

        current_module.meta[:options][option][:value] = value
      end

      private

      def truthy?(value)
        TRUTHY_VALUES.include?(value.downcase)
      end

      def falsy?(value)
        FALSY_VALUES.include?(value.downcase)
      end

      def current_module
        console.current_module
      end
    end
  end
end
