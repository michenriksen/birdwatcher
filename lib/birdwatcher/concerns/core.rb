module Birdwatcher
  module Concerns
    module Core

      # Location of the data directory
      # @private
      DATA_DIRECTORY = File.expand_path(
        File.join(File.dirname(__FILE__), "..", "..", "..", "data")
      ).freeze

      class DataFileNotFoundError < StandardError; end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Get the current Console instance
      #
      # @return [Birdwatcher::Console]
      def console
        Birdwatcher::Console.instance
      end

      # Get the currently active workspace model object
      #
      # The current workspace is represented by its Sequel data model and can be
      # used to query for data associated with the workspace.
      #
      # Please read the Sequel gem documentation for more information about how
      # to use the model.
      #
      # @return [Birdwatcher::Models::Workspace] instance of the currently active workspace
      # @see http://sequel.jeremyevans.net/documentation.html
      def current_workspace
        Birdwatcher::Console.instance.current_workspace
      end

      # Set the current workspace
      #
      # @param workspace [Birdwatcher::Models::Workspace]
      def current_workspace=(workspace)
        Birdwatcher::Console.instance.current_workspace = workspace
      end

      # Get a Twitter API client
      #
      # The Twitter API is being queried with the Twitter gem which provides an
      # easy and intuitive interface to the API and its data objects. Please see
      # the Twitter gem documentation for information on how to use the Twitter
      # gem.
      #
      # The method will return an instance configured with a random Twitter API
      # keypair from the +~/.birdwatcherrc+ configuration file.
      #
      # @return instance of Twitter::REST::Client
      # @see https://github.com/sferik/twitter
      # @see http://www.rubydoc.info/gems/twitter
      def twitter_client
        Birdwatcher::Console.instance.twitter_client
      end

      # Get a Klout API client
      #
      # The Klout API provides information about Twitter users such as their
      # general "social score", topics of interest and social influence graph.
      #
      # The method will return an instance configured with a random API key from
      # the +~/.birdwatcherrc+ configuration file.
      #
      # @return [Birdwatcher::KloutClient]
      # @see https://klout.com/s/developers/v2
      def klout_client
        Birdwatcher::Console.instance.klout_client
      end

      # Get the raw database client instance
      #
      # The raw database client object can be used to execute raw SQL queries
      # against the configured database, however the {current_workspace} method
      # should be used whenever possible to execute SQL queries through the
      # current workspace's {Sequel::Model} instance instead. This ensures that
      # the data returned is isolated to the current workspace.
      #
      # @return [Sequel::Database]
      def database
        Birdwatcher::Console.instance.database
      end

      # Get the contents of a data file
      #
      # @param name [String] file name to read
      #
      # @return contents of file in Birdwatcher's data directory
      # @raise [Birdwatcher::Concerns::Core::DataFileNotFoundError] if the file doesn't exist
      def read_data_file(name)
        path = File.join(DATA_DIRECTORY, name)
        fail(DataFileNotFoundError, "File #{name} was not found in data directory") unless File.exists?(path)
        File.read(path)
      end
    end
  end
end
