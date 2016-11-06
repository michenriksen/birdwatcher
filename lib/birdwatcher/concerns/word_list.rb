module Birdwatcher
  module Concerns
    module WordList
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Get a new word list instance
      #
      # @param options [Hash] Word list options
      #
      # @return [Birdwatcher::WordList]
      def make_word_list(options = {})
        Birdwatcher::WordList.new(options)
      end
    end
  end
end
