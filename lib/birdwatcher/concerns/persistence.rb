module Birdwatcher
  module Concerns
    module Persistence
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Save a Twitter status to the database
      #
      # @param status [Twitter::Tweet]
      # @param user   [Birdwatcher::Models::User] Author of status
      #
      # The status will be linked to the current workspace. All URLs, hashtags
      # and mentions will automatically be extracted and saved as separate models.
      #
      # @return [Birdwatcher::Models::Status]
      def save_status(status, user)
        current_workspace = Birdwatcher::Console.instance.current_workspace
        db_status = current_workspace.add_status(
          :user_id            => user.id,
          :twitter_id         => status.id.to_s,
          :text               => Birdwatcher::Util.strip_control_characters(Birdwatcher::Util.unescape_html(status.text)),
          :source             => Birdwatcher::Util.strip_control_characters(Birdwatcher::Util.strip_html(status.source)),
          :retweet            => status.retweet?,
          :geo                => status.geo?,
          :favorite_count     => status.favorite_count,
          :retweet_count      => status.retweet_count,
          :possibly_sensitive => status.possibly_sensitive?,
          :lang               => status.lang,
          :posted_at          => status.created_at,
        )
        if status.geo? && status.geo.coordinates
          db_status.longitude = status.geo.coordinates.first
          db_status.latitude  = status.geo.coordinates.last
        end
        if status.place?
          db_status.place_type         = status.place.place_type
          db_status.place_name         = Birdwatcher::Util.strip_control_characters(status.place.name)
          db_status.place_country_code = Birdwatcher::Util.strip_control_characters(status.place.country_code)
          db_status.place_country      = Birdwatcher::Util.strip_control_characters(status.place.country)
        end
        db_status.save
        if status.hashtags?
          status.hashtags.each do |hashtag|
            tag = Birdwatcher::Util.strip_control_characters(hashtag.text)
            db_hashtag = current_workspace.hashtags_dataset.first(:tag => tag) || current_workspace.add_hashtag(:tag => tag)
            db_status.add_hashtag(db_hashtag)
          end
        end
        if status.user_mentions?
          status.user_mentions.each do |mention|
            screen_name = Birdwatcher::Util.strip_control_characters(mention.screen_name)
            name        = Birdwatcher::Util.strip_control_characters(mention.name)
            db_mention  = current_workspace.mentions_dataset.first(:twitter_id => mention.id.to_s) || current_workspace.add_mention(:twitter_id => mention.id.to_s, :screen_name => screen_name, :name => name)
            db_status.add_mention(db_mention)
          end
        end
        if status.urls?
          status.urls.each do |url|
            expanded_url = Birdwatcher::Util.strip_control_characters(url.expanded_url.to_s)
            db_url = current_workspace.urls_dataset.first(:url => expanded_url) || current_workspace.add_url(:url => expanded_url)
            db_status.add_url(db_url)
          end
        end
        db_status
      end

      # Save a Twitter user to the database
      #
      # @param user [Twitter::User]
      #
      # The user will be linked to the current workspace
      #
      # @return [Birdwatcher::Models::User]
      def save_user(user)
        Birdwatcher::Console.instance.current_workspace.add_user(
          :twitter_id        => user.id.to_s,
          :screen_name       => Birdwatcher::Util.strip_control_characters(user.screen_name),
          :name              => Birdwatcher::Util.strip_control_characters(user.name),
          :location          => Birdwatcher::Util.strip_control_characters(user.location),
          :description       => Birdwatcher::Util.strip_control_characters(user.description),
          :url               => (user.website_urls.first ? Birdwatcher::Util.strip_control_characters(user.website_urls.first.expanded_url.to_s) : nil),
          :profile_image_url => user.profile_image_url_https.to_s,
          :followers_count   => user.followers_count,
          :friends_count     => user.friends_count,
          :listed_count      => user.listed_count,
          :favorites_count   => user.favorites_count,
          :statuses_count    => user.statuses_count,
          :utc_offset        => user.utc_offset,
          :timezone          => user.time_zone,
          :geo_enabled       => user.geo_enabled?,
          :verified          => user.verified?,
          :lang              => user.lang
        )
      end
    end
  end
end
