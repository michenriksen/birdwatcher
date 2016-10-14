module Birdwatcher
  module Commands
    class Module < Birdwatcher::Command
      self.meta = {
        :description => "Show modules",
        :names       => %w(module modules),
        :usage       => "module ACTION"
      }

      def self.detailed_usage
<<-USAGE
The #{'modules'.bold} command shows information about available Birdwatcher modules.

#{'USAGE:'.bold}

#{'See available modules and short descriptions:'.bold}
  modules list

#{'See detailed information on specific module:'.bold}
  modules info MODULE_PATH

#{'Search for modules with the word "import" in their name, description or path:'.bold}
  modules search import

#{'List all modules related to users:'.bold}
  modules search users/
USAGE
      end

      def run
        if !arguments?
          show_modules
          return
        end
        action = arguments.first.downcase
        case action
        when "show", "info", "view"
          show_module(arguments[1])
        when "list", "-l"
          show_modules
        when "search", "-s"
          search_modules
        else
          show_module(arguments.first)
        end
      end

      private

      def show_module(path)
        if !_module = Birdwatcher::Module.module_by_path(path)
          error("Unknown module: #{arguments[1].bold}")
          return false
        end
        newline
        output "       Name: ".bold + _module.meta[:name]
        output "Description: ".bold + _module.meta[:description]
        output "     Author: ".bold + _module.meta[:author]
        output "       Path: ".bold + _module.path
        newline
        line_separator
        newline
        if _module.info
          output _module.info
        else
          info("No further information has been provided for this module")
        end
        newline
      end

      def show_modules
        info("Available Modules:\n")
        Birdwatcher::Module.descendants.sort_by(&:path).each do |_module|
          output_module_summary(_module)
        end
      end

      def search_modules
        search_term = arguments[1..-1].join(" ").downcase
        modules     = []
        Birdwatcher::Module.descendants.sort_by(&:path).each do |_module|
          if _module.path.include?(search_term) || _module.meta[:name].downcase.include?(search_term) || _module.meta[:description].downcase.include?(search_term)
            modules << _module
          end
        end
        if modules.empty?
          info("No modules found with search: #{search_term.bold}")
        else
          info("Module Search Results:\n")
          modules.each do |_module|
            output_module_summary(_module)
          end
        end
      end

      def output_module_summary(_module)
        output "       Name: ".bold + _module.meta[:name]
        output "Description: ".bold + _module.meta[:description]
        output "       Path: ".bold + _module.path
        newline
        line_separator
        newline
      end
    end
  end
end
