module Birdwatcher
  module Models
    class Url < Sequel::Model
      many_to_one :workspace
      many_to_many :statuses
    end
  end
end
