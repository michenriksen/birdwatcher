module Birdwatcher
  class KloutClient < Birdwatcher::HttpClient
    base_uri "https://api.klout.com/v2"

    # Class initializer
    #
    # @param api_key [String] Klout API key
    # @param options Http client options
    # @see Birdwatcher::HttpClient
    def initialize(api_key, options = {})
      @api_key = api_key
      @options = {
        :headers => {
          "User-Agent" => "Birdwatcher v#{Birdwatcher::VERSION}",
          "Accept"     => "application/json"
        }
      }.merge(options)
    end

    # Get Klout ID of a Twitter user
    #
    # @param screen_name [String] Twitter screen name
    # @return [String] Klout ID or nil
    # @see https://klout.com/s/developers/v2#identities
    def get_id(screen_name)
      response = do_get("/identity.json/twitter?screenName=#{url_encode(screen_name)}&key=#{url_encode(@api_key)}")
      if response.status == 200
        JSON.parse(response.body)["id"]
      end
    end

    # Get Klout score of a user
    #
    # @param klout_id [String]
    # @return [Numeric] Klout score or nil
    # @see https://klout.com/s/developers/v2#scores
    def get_score(klout_id)
      response = do_get("/user.json/#{klout_id}/score?key=#{url_encode(@api_key)}")
      if response.status == 200
        JSON.parse(response.body)["score"]
      end
    end

    # Get Klout topics of a user
    #
    # @param klout_id [String]
    # @return [Array] Topics
    # @see https://klout.com/s/developers/v2#topic
    def get_topics(klout_id)
      response = do_get("/user.json/#{klout_id}/topics?key=#{url_encode(@api_key)}")
      if response.status == 200
        JSON.parse(response.body).map { |t| t["displayName"] }
      end
    end

    # Get Klout influence graph of a user
    #
    # @param klout_id [String]
    # @return [Hash] +:influencers:+ contains screen names of influencers, +:influencees+ contains screen names of influencees
    # @see https://klout.com/s/developers/v2#influence
    def get_influence(klout_id)
      response = do_get("/user.json/#{klout_id}/influence?key=#{url_encode(@api_key)}")
      if response.status == 200
        body = JSON.parse(response.body)
        {
          :influencers => body["myInfluencers"].map { |i| i["entity"]["payload"]["nick"] },
          :influencees => body["myInfluencees"].map { |i| i["entity"]["payload"]["nick"] }
        }
      end
    end

    private

    # URL encode a string
    # @private
    #
    # @param string [String]
    # @return [String] URL encoded string
    def url_encode(string)
      CGI.escape(string.to_s)
    end
  end
end
