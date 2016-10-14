module Birdwatcher
  module Concerns
    module Concurrency
      # The default size of thread pool
      # @private
      DEFAULT_THREAD_POOL_SIZE = 10.freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Create a new thread pool
      #
      # @param size [Integer] OPTIONAL: The size of the thread pool (default size if not specified)
      # @return [Thread::Pool]
      # @see https://github.com/meh/ruby-thread#pool
      def thread_pool(size = nil)
        Thread.pool(size || DEFAULT_THREAD_POOL_SIZE)
      end
    end
  end
end
