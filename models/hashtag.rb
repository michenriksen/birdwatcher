module Birdwatcher
  module Models
    class Hashtag < Sequel::Model
      many_to_one :workspace
      many_to_many :statuses
    end
  end
end
