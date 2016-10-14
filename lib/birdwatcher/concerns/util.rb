module Birdwatcher
  module Concerns
    module Util
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Get the relative time for a timestamp
      #
      # @param time [Time] Timestamp to be converted
      #
      # @example getting relative time of a status
      #     status = current_workspace.statuses.last
      #     output time_ago_in_words(status.posted_at)
      #     #=> "1 day and 15 hours ago"
      #
      # @return [String] relative time in words
      def time_ago_in_words(time)
        Birdwatcher::Util.time_ago_in_words(time)
      end

      # Natural language parsing of time
      #
      # @param time [String] A string representing a time (e.g. "yesterday at 4:00")
      #
      # Uses the Chronic gem to perform natural language parsing of time.
      # See the examples in Chronic's documentation for strings that can be parsed.
      #
      # All modules that can be configured with times, should perform natural
      # language parsing on the option setting for better user experience.
      #
      # @return [Time]
      # @see https://github.com/mojombo/chronic
      # @see https://github.com/mojombo/chronic#examples
      def parse_time(time)
        Birdwatcher::Util.parse_time(time)
      end

      # Correct pluralization of word depending on count
      #
      # @param count [Integer] The amount
      # @param singular [String] The singular word
      # @param plural [String] The plural word
      #
      # pluralizes the singular word unless count is 1.
      #
      # @example
      #     pluralize(1, "user", "users")
      #     #=> "1 user"
      #
      #     pluralize(5, "user", "users")
      #     #=> "5 users"
      #
      #     pluralize(0, "user", "users")
      #     #=> "0 users"
      def pluralize(count, singular, plural)
        Birdwatcher::Util.pluralize(count, singular, plural)
      end

      # Strip out HTML tags from a string
      #
      # @param string [String] String to strip HTML tags from
      #
      # @return [String] HTML stripped string
      def strip_html(string)
        Birdwatcher::Util.strip_html(string)
      end

      # Strip out control characters and color codes from a string
      #
      # @param string [String] String to strip control characters from
      #
      # @return [String] String without control characters
      def strip_control_characters(string)
        Birdwatcher::Util.strip_control_characters(string)
      end

      # Escape special HTML characters with HTML entities
      #
      # @param string [String] String to HTML escape
      #
      # @return [String] HTML escaped string
      def escape_html(string)
        Birdwatcher::Util.escape_html(string)
      end

      # Unescape special HTML characters in a string
      #
      # @param string [String] String to unescape
      #
      # @return [String] string with escaped special HTML characters unescaped
      def unescape_html(string)
        Birdwatcher::Util.unescape_html(string)
      end

      # Create an excerpt of potentially long text at a fixed length
      #
      # @param text [String] Text to excerpt
      # @param max_length [Integer] Maximum length of text before being excerpted
      # @param omission [String] OPTIONAL: String to append to text if excerpted
      #
      # @example
      #     excerpt("The quick brown fox jumps over the lazy dog", 80)
      #     #=> "The quick brown fox jumps over the lazy dog"
      #
      #     excerpt("The quick brown fox jumps over the lazy dog", 40)
      #     #=> "The quick brown fox jumps over the lazy d..."
      #
      # @return [String] excerpted text
      def excerpt(text, max_length, omission = "...")
        Birdwatcher::Util.excerpt(text, max_length, omission)
      end

      # Suppress any potential output to STDOUT
      #
      # Used in cases where certain libraries or methods might output unwanted
      # text to +STDOUT+ without any possibility of disabling it.
      #
      # @param block code block to run with output suppression
      def suppress_output(&block)
        Birdwatcher::Util.suppress_output(&block)
      end

      # Suppress any warning messages to STDOUT
      #
      # Used in cases where certain libraries or methods might output unwanted
      # warning messages to +STDOUT+.
      #
      # @param block code block to run with warning suppression
      def suppress_warnings(&block)
        Birdwatcher::Util.suppress_warnings(&block)
      end
    end
  end
end
