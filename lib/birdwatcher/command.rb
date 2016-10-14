module Birdwatcher
  class Command
    class Error < StandardError; end
    class InvalidMetadataError < Error; end
    class MetadataNotSetError < Error; end

    ARGUMENT_SEPARATOR = " ".freeze

    attr_reader :arguments

    include Birdwatcher::Concerns::Core
    include Birdwatcher::Concerns::Util
    include Birdwatcher::Concerns::Outputting
    include Birdwatcher::Concerns::Presentation
    include Birdwatcher::Concerns::Persistence
    include Birdwatcher::Concerns::Concurrency

    def self.meta
      @meta || fail(MetadataNotSetError, "Metadata has not been set")
    end

    def self.meta=(meta)
      validate_metadata(meta)
      @meta = meta
    end

    def self.detailed_usage; end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.has_name?(name)
      meta[:names].include?(name)
    end

    def self.auto_completion_strings
      (meta[:names] + auto_completion).uniq
    end

    def self.auto_completion
      []
    end

    def execute(argument_line)
      @arguments = argument_line.to_s.split(ARGUMENT_SEPARATOR).map { |a| a.to_s.strip }
      run
    rescue => e
      error("#{e.class}".bold + ": #{e.message}")
      puts e.backtrace.join("\n")
    end

    protected

    def run
      fail NotImplementedError, "Commands must implement #run method"
    end

    def arguments?
      !arguments.empty?
    end

    def commands
      Birdwatcher::Command.descendants
    end

    def self.validate_metadata(meta)
      fail InvalidMetadataError, "Metadata is not a hash" unless meta.is_a?(Hash)
      fail InvalidMetadataError, "Metadata is empty" if meta.empty?
      fail InvalidMetadataError, "Metadata is missing key: description" unless meta.key?(:description)
      fail InvalidMetadataError, "Metadata is missing key: names" unless meta.key?(:names)
      fail InvalidMetadataError, "Metadata is missing key: usage" unless meta.key?(:usage)
      fail InvalidMetadataError, "Metadata names is not an array" unless meta[:names].is_a?(Array)
      fail InvalidMetadataError, "Metadata names must contain at least one string" if meta[:names].empty?
      fail InvalidMetadataError, "Metadata usage is not string" unless meta[:usage].is_a?(String)
    end
  end
end
