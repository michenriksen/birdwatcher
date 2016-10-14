module Birdwatcher
  module Models
    class User < Sequel::Model
      many_to_one :workspace
      one_to_many :statuses
      many_to_many :klout_topics
      many_to_many :influencers
      many_to_many :influencees
    end
  end
end
