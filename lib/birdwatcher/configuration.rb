module Birdwatcher
  class Configuration
    include Singleton

    CONFIGURATION_FILE_NAME     = ".birdwatcherrc".freeze
    CONFIGURATION_FILE_LOCATION = File.join(Dir.home, CONFIGURATION_FILE_NAME).freeze

    class Error < StandardError; end
    class ConfigurationFileNotFound < Error; end
    class ConfigurationFileNotReadable < Error; end
    class ConfigurationFileCorrupt < Error; end
    class UnknownKey < Error; end

    def self.get!(key)
      self.instance.get!(key)
    end

    def self.get(key)
      self.instance.get!(key)
    rescue Birdwatcher::Configuration::UnknownKey
      nil
    end

    def self.configured?
      File.exist?(CONFIGURATION_FILE_LOCATION)
    end

    def self.save!(configuration)
      File.open(CONFIGURATION_FILE_LOCATION, "w") do |f|
        f.write(YAML.dump(configuration))
      end
    end

    def self.load!
      self.instance.load_configuration!
    end

    def load_configuration!
      if !File.exist?(CONFIGURATION_FILE_LOCATION)
        fail ConfigurationFileNotFound, "Configuration file does not exist"
      end
      if !File.readable?(CONFIGURATION_FILE_LOCATION)
        fail ConfigurationFileNotReadable, "Configuration file is not readable"
      end
      @configuration = YAML.load_file(CONFIGURATION_FILE_LOCATION).inject({}) { |memo, (k,v)| memo[k.to_sym] = v; memo }
    rescue ::Psych::SyntaxError => e
      raise ConfigurationFileCorrupt, "Configuration file contains invalid YAML"
    end

    def get!(key)
      key = key.to_sym
      fail(UnknownKey, "Unknown configuration key: #{key}") unless configuration.key?(key)
      configuration[key.to_sym]
    end

    private

    def configuration
      load_configuration! unless @configuration
      @configuration
    end
  end
end
