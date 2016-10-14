module Birdwatcher
  module Commands
    class Show < Birdwatcher::Command
      self.meta = {
        :description => "Show module details and options",
        :names       => %w(show),
        :usage       => "show DETAILS"
      }

      def self.detailed_usage
<<-USAGE
The #{'show'.bold} command shows information and options on Birdwatcher
modules.

#{'USAGE:'.bold}

#{'See available module options:'.bold}
  show options

#{'See additional module information:'.bold}
  show info
USAGE
      end

      def run
        if !arguments?
          error("You must specify what to see")
          return false
        end

        if !current_module
          error("No module loaded")
          return false
        end

        case arguments.first
        when "info", "description", "details"
          output_info
        when "options", "opts"
          output_options
        else
          error("Don't know how to show #{arguments.first.bold}")
          return false
        end
      end

      private

      def output_info
        newline
        output "       Name: ".bold + current_module.meta[:name]
        output "Description: ".bold + current_module.meta[:description]
        output "     Author: ".bold + current_module.meta[:author]
        output "       Path: ".bold + current_module.path
        newline
        line_separator
        newline
        if current_module.info
          output current_module.info
        else
          info("No further information has been provided for this module")
        end
        newline
      end

      def output_options
        if current_module.meta[:options].empty?
          info("This module has no options")
          return
        end
        table = Terminal::Table.new(:headings => ["Name", "Current Setting", "Required", "Description"].map(&:bold))
        table.style = { :border_y => "", :border_i => "" }
        current_module.meta[:options].each_pair do |key, value|
          table.add_row([key, value[:value], (value[:required] ? 'yes' : 'no'), value[:description]])
        end
        newline
        output table
        newline
      end

      def current_module
        console.current_module
      end
    end
  end
end
