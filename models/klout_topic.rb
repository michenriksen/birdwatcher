module Birdwatcher
  module Models
    class KloutTopic < Sequel::Model
      many_to_one :workspace
      many_to_many :users
    end
  end
end
