module Birdwatcher
  module Models
    class Status < Sequel::Model
      many_to_one :workspace
      many_to_one :user
      many_to_many :mentions
      many_to_many :hashtags
      many_to_many :urls
    end
  end
end
