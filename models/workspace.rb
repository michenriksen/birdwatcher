module Birdwatcher
  module Models
    class Workspace < Sequel::Model
      DEFAULT_WORKSPACE_NAME        = "default".freeze
      DEFAULT_WORKSPACE_DESCRIPTION = "Default workspace".freeze

      one_to_many :users
      one_to_many :statuses
      one_to_many :hashtags
      one_to_many :mentions
      one_to_many :urls
      one_to_many :klout_topics

      def self.create_default_workspace!
        self.create(
          :name        => DEFAULT_WORKSPACE_NAME,
          :description => DEFAULT_WORKSPACE_DESCRIPTION
        )
      end

      def default_workspace?
        self.name == DEFAULT_WORKSPACE_NAME
      end
    end
  end
end
