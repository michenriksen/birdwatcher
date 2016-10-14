module Birdwatcher
  module Concerns
    module Outputting
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Output data to the console
      #
      # Simply outputs the given data to the console.
      #
      # For more convenient and consistant outputting, see the {info}, {task},
      # {error}, {warn} and {fatal} methods.
      def output(data)
        Birdwatcher::Console.instance.output(data)
      end

      # Output formatted data to the console
      #
      # Outputs data with +printf+ formatting.
      #
      # @example
      #    output_formatted("%-15s %s\n", title, description)
      #
      # @param *args Args to be passed
      def output_formatted(*args)
        Birdwatcher::Console.instance.output_formatted(*args)
      end

      # Output a newline to the console
      #
      # Used for consistant spacing in console output
      def newline
        Birdwatcher::Console.instance.newline
      end

      # Output a line to the console
      #
      # Used for consistant spacing and separation between console output
      def line_separator
        Birdwatcher::Console.instance.line_separator
      end

      # Output an informational message to the console
      #
      # @param message [String] Message to display
      #
      # Formats the message as an informational message
      def info(message)
        Birdwatcher::Console.instance.info(message)
      end

      # Output an informational message to the console that reports when a
      # longer-running task is done.
      #
      # @param message [String] Message to display
      # @param fatal [Boolean] OPTIONAL if an exception is raised, treat it as a fatal error
      # @param block The code block to yield
      #
      # @example performing a long-running task
      #    task("Performing a long, time consuming task...") do
      #      long_running_task
      #    end
      def task(message, fatal = false, &block)
        Birdwatcher::Console.instance.task(message, fatal, &block)
      end

      # Output an error message to the console
      #
      # @param message [String] Message to display
      #
      # Formats the message as an error message
      def error(message)
        Birdwatcher::Console.instance.error(message)
      end

      # Output a warning message to the console
      #
      # @param message [String] Message to display
      #
      # Formats the message as a warning message
      def warn(message)
        Birdwatcher::Console.instance.warn(message)
      end

      # Output a fatal message to the console
      #
      # @param message [String] Message to display
      #
      # Formats the message as a fatal message
      def fatal(message)
        Birdwatcher::Console.instance.fatal(message)
      end

      # Ask the user for confirmation
      #
      # @param question [String] Yes/No question to ask the user
      #
      # Waits for the user to answer Yes or No to a question. Useful for making
      # the user confirm destructive actions before executing them.
      #
      # @example make user confirm division by zero
      #    if confirm("Do you really want divide by zero?")
      #      0 / 0
      #    end
      def confirm(question)
        HighLine.agree("#{question} (y/n) ")
      end
    end
  end
end
