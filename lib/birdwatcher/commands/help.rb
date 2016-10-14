module Birdwatcher
  module Commands
    class Help < Birdwatcher::Command
      self.meta = {
        :description => "Show help and detailed command usage",
        :names       => %w(help ?),
        :usage       => "help [COMMAND]"
      }

      def self.detailed_usage
<<-USAGE
The #{'help'.bold} command shows a general overview of available commands as well as help
and detailed usage for specific commands.

#{'USAGE:'.bold}

#{'See available commands and short descriptions:'.bold}
  help

#{'See help and detailed usage for specific command:'.bold}
  help COMMAND
USAGE
      end

      def run
        if arguments?
          show_command_help
        else
          show_general_help
        end
      end

      private

      def show_command_help
        command_name = arguments.first.downcase
        commands.each do |command|
          next unless command.has_name?(command_name)
          if command.detailed_usage
            newline
            output command.detailed_usage
          else
            info("There is no detailed usage for this command")
          end
          return
        end
        error "Unknown command: #{command_name}"
      end

      def show_general_help
        longest_command_usage = commands.map { |c| c.meta[:usage] }.max_by(&:length)
        info "Available commands:\n"
        commands.sort_by { |c| c.meta[:usage] }.each do |command|
          output_formatted("    %-#{longest_command_usage.bold.length}s\t\t%s\n", command.meta[:usage].bold, command.meta[:description])
        end
        newline
      end
    end
  end
end
