module Birdwatcher
  class Module
    class Error < StandardError; end
    class InvalidMetadataError < Error; end
    class MetadataNotSetError < Error; end
    class UnknownOptionError < Error; end

    include Birdwatcher::Concerns::Core
    include Birdwatcher::Concerns::Util
    include Birdwatcher::Concerns::Outputting
    include Birdwatcher::Concerns::Presentation
    include Birdwatcher::Concerns::Persistence
    include Birdwatcher::Concerns::Concurrency

    # Path to modules directory
    # @private
    MODULE_PATH = File.join(File.dirname(__FILE__), "modules").freeze

    # Get the module's file path
    # @private
    def self._file_path
      @_file_path
    end

    # Set the module's file path
    # @private
    #
    # @param path [String] file path
    def self._file_path=(path)
      @_file_path = path
    end

    # Automatically set the module file path
    # @private
    def self.inherited(k)
      k._file_path = caller.first[/^[^:]+/]
    end

    # Get the module's meta data
    # @private
    #
    # @return [Hash] meta data
    # @raise [Birdwatcher::Model::MetadataNotSetError] if meta data has not been set
    def self.meta
      @meta || fail(MetadataNotSetError, "Metadata has not been set")
    end

    # Set the module's meta data
    #
    # @param meta [Hash] meta data
    #
    # The module's meta data is used by Birdwatcher to provide the user with
    # useful information such as name, a short description of what it does as
    # well as the author of the module in case they have any questions, etc.
    #
    # The meta data MUST be a hash and MUST contain at least the following keys:
    # * +:name+: The module's name (e.g. User Importer)
    # * +:description+: A short description of what the module can do
    # * +:author+: Your name and email (e.g. John Doe <john@doe.com>)
    # * +:options+: A hash of options for the module
    #
    # The +:options+ meta data key MUST be a Hash where each key is the option name
    # in UPPERCASE. The value MUST be a Hash and MUST contain at least the following
    # keys:
    # * +:value+: The default value of the option setting (set to +nil+ if none)
    # * +:description+: A short description of the option setting
    # * +:required+: Set to +true+ if the option setting is required to be set
    #
    # If the option setting is a boolean flag, the +:boolean+ key can be set to
    # +true+ to have Birdwatcher automatically parse "truthy" and "falsy" values
    # (e.g. "true", "1", "yes", "no", "0", etc) into boolean true or false
    #
    # If an option setting's +:required+ key is set to +true+, Birdwatcher will
    # automatically prevent running of the module if any of those option settings
    # contain +nil+ (have not been set).
    #
    # @example Example meta data:
    #     self.meta = {
    #       :name        => "User Importer",
    #       :description => "Import users from a file containing screen names",
    #       :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
    #       :options     => {
    #         "FILE" => {
    #           :value       => nil,
    #           :description => "File to read screen names from.",
    #           :required    => true
    #         }
    #       }
    #     }
    def self.meta=(meta)
      validate_metadata(meta)
      @meta = meta
    end

    # Get a module by it's path
    # @private
    #
    # @param path [String] Module's short path
    #
    # @return [Birdwatcher::Module] descendant
    def self.module_by_path(path)
      modules[path]
    end

    # Get module short paths
    # @private
    def self.module_paths
      modules.keys
    end

    # Get the module's short path
    # @private
    def self.path
      @_file_path.gsub("#{MODULE_PATH}/", "").gsub(".rb", "")
    end

    # The module's detailed information and usage
    #
    # @abstract
    #
    # This method can be overwritten by modules to provide additional information
    # and usage to the user. The method will be called when the user envokes the
    # +show info+ on the module.
    #
    # The method must return a string.
    #
    # @return [String] additional module information
    def self.info; end

    # Get all Birdwatcher::Module descendants
    # @private
    #
    # @return [Array] module classes
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    # Get all Birdwatcher modules sorted by their short path
    # @private
    #
    # @return [Hash] module classes where the key is the module's short path
    def self.modules
      if !@modules
        @modules = {}
        descendants.each do |descendant|
          @modules[descendant.path] = descendant
        end
      end
      @modules
    end

    # Execute a module and catch any exceptions raised
    # @private
    #
    # Calls the module's {run} method if options are valid and catches any
    # exceptions raised to display an error to the user.
    def execute
      validate_options && run
    rescue => e
      error("#{e.class}".bold + ": #{e.message}")
      puts e.backtrace.join("\n")
    end

    # The module's run method
    #
    # @abstract
    #
    # The run method must be overwritten by modules to perform the actual work.
    # The method is called when the user envokes the +run+ command in the
    # Birdwatcher console.
    #
    # If the module fails to run for whatever reason, e.g. insufficient data, the
    # method should return +false+.
    def run
      fail NotImplementedError, "Modules must implement #run method"
    end

    protected

    # Validate option settings
    # @private
    #
    # @return [Boolean] true if meta data is valid and false otherwise
    def validate_options
      options.each_pair do |key, value|
        if value[:required] && value[:value].nil?
          error("Setting for required option has not been set: #{key.bold}")
          return false
        end
      end
    end

    # Validate module meta data
    # @private
    #
    # @param meta [Hash] meta data
    #
    # @raise [Birdwatcher::Module::InvalidMetadataError] if meta data is not valid.
    def self.validate_metadata(meta)
      fail InvalidMetadataError, "Metadata is not a hash" unless meta.is_a?(Hash)
      fail InvalidMetadataError, "Metadata is empty" if meta.empty?
      fail InvalidMetadataError, "Metadata is missing key: name" unless meta.key?(:name)
      fail InvalidMetadataError, "Metadata is missing key: description" unless meta.key?(:description)
      fail InvalidMetadataError, "Metadata is missing key: author" unless meta.key?(:author)
      fail InvalidMetadataError, "Metadata is missing key: options" unless meta.key?(:options)
      fail InvalidMetadataError, "Metadata name is not a string" unless meta[:name].is_a?(String)
      fail InvalidMetadataError, "Metadata description is not a string" unless meta[:description].is_a?(String)
      fail InvalidMetadataError, "Metadata author is not a string" unless meta[:author].is_a?(String)
      validate_metadata_options(meta[:options])
    end

    # Validate meta data module options
    # @private
    #
    # @param options [Hash] options
    #
    # Automatically called by {validate_metadata}
    #
    # @raise [Birdwatcher::Module::InvalidMetadataError] if options hash is not valid.
    def self.validate_metadata_options(options)
      fail InvalidMetadataError, "Metadata options is not a hash" unless options.is_a?(Hash)
      options.each_pair do |key, value|
        fail("Option key #{key} must be all uppercase") unless (key == key.upcase)
        fail("Option value for #{key} is not a hash") unless value.is_a?(Hash)
        fail("Option value for #{key} is missing key: value") unless value.key?(:value)
        fail("Option value for #{key} is missing key: description") unless value.key?(:description)
        fail("Option value for #{key} is missing key: required") unless value.key?(:required)
      end
    end

    # Get the module's options hash
    # @private
    #
    # @return [Hash] options meta data hash.
    def options
      self.class.meta[:options]
    end

    # Get an option setting
    #
    # @example getting option settings
    #     option_setting("DEST")
    #     option_setting("USERS")
    #
    # @return option setting
    # @raise [Birdwatcher::Module::UnknownOptionError] if option is unknown
    def option_setting(option)
      option = option.to_s.upcase
      fail UnknownOptionError, "Unknown module option: #{option}" unless options.keys.include?(option)
      options[option][:value]
    end
  end
end
