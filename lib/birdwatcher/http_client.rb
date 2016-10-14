module Birdwatcher
  class HttpClient
    include HTTParty

    # Default request timeout
    DEFAULT_TIMEOUT = 15.freeze

    # Default request retries
    DEFAULT_RETRIES = 2.freeze

    Response = Struct.new(:url, :status, :headers, :body)

    # List of retriable exceptions
    RETRIABLE_EXCEPTIONS = [
      Errno::ETIMEDOUT,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::ENETUNREACH,
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      SocketError,
      Net::OpenTimeout,
      EOFError
    ].freeze

    # List of User-Agent strings to use for client spoofing
    USER_AGENTS = [
      "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.8 (KHTML, like Gecko) Version/9.1.3 Safari/601.7.8",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:48.0) Gecko/20100101 Firefox/48.0",
      "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:48.0) Gecko/20100101 Firefox/48.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Safari/602.1.50",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.7 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.7",
      "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
      "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"
    ].freeze

    # Class initializer
    #
    # @params options [Hash] client options
    # @option options :timeout [Integer] request timeout
    # @option options :retries [Integer] request retries
    # @option options :user_agent [String] User-Agent to use (random if not set)
    # @option options :retriable_exceptions [Array] exception classes to retry on
    #
    # @note The options list is incomplete; the class supports all options for the HTTParty gem
    # @see http://www.rubydoc.info/github/jnunemaker/httparty/HTTParty/ClassMethods
    def initialize(options = {})
      @options = {
        :timeout              => DEFAULT_TIMEOUT,
        :retries              => DEFAULT_RETRIES,
        :user_agent           => nil,
        :retriable_exceptions => RETRIABLE_EXCEPTIONS
      }.merge(options)
    end

    # Perform a GET request
    #
    # @param path [String] Path to request
    # @param params [Hash] Request params
    # @param options [Hash] Request options
    # @return [Birdwatcher::HttpClient::Response]
    def do_get(path, params=nil, options={})
      do_request(:get, path, {:query => params}.merge(options))
    end

    # Perform a HEAD request
    #
    # @param path [String] Path to request
    # @param params [Hash] Request params
    # @param options [Hash] Request options
    # @return [Birdwatcher::HttpClient::Response]
    def do_head(path, params=nil, options={})
      do_request(:head, path, {:query => params}.merge(options))
    end

    # Perform a POST request
    #
    # @param path [String] Path to request
    # @param params [Hash] Request params
    # @param options [Hash] Request options
    # @return [Birdwatcher::HttpClient::Response]
    def do_post(path, params=nil, options={})
      do_request(:post, path, {:query => params}.merge(options))
    end

    # Perform a PUT request
    #
    # @param path [String] Path to request
    # @param params [Hash] Request params
    # @param options [Hash] Request options
    # @return [Birdwatcher::HttpClient::Response]
    def do_put(path, params=nil, options={})
      do_request(:put, path, {:query => params}.merge(options))
    end

    # Perform a DELETE request
    #
    # @param path [String] Path to request
    # @param params [Hash] Request params
    # @param options [Hash] Request options
    # @return [Birdwatcher::HttpClient::Response]
    def do_delete(path, params=nil, options={})
      do_request(:delete, path, {:query => params}.merge(options))
    end

    private

    # Perform a request
    # @private
    #
    # @param method [Symbol] Class method to call
    # @param path [String] Request path
    # @param options [Hash] Request options
    #
    # @return Birdwatcher::HttpClient::Response
    def do_request(method, path, options)
      opts = @options.merge({
          :headers => {
            "Accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Encoding" => "gzip",
            "Accept-Language" => "en-US,en;q=0.8",
            "Cache-Control"   => "max-age=0",
            "Connection"      => "close",
            "User-Agent"      => @options[:user_agent] || USER_AGENTS.sample
          },
          :verify => false
        }).merge(options)
      with_retries do
        response = self.class.send(method, path, opts)
        Response.new(response.request.last_uri.to_s, response.code, response.headers, response.body)
      end
    end

    # Execute code block and retry if a retriable exception is raised
    # @private
    #
    # @param &block Code block to run
    def with_retries(&block)
      tries = @options[:retries].to_i
      yield
    rescue *@options[:retriable_exceptions] => ex
      tries -= 1
      if tries > 0
        sleep 0.2
        retry
      else
        raise ex
      end
    end
  end
end
