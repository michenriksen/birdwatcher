module Birdwatcher
  module Concerns
    module Presentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      # Make a user summary output
      #
      # @param user [Birdwatcher::Models::User]
      #
      # @return [String] Short summary of the user
      def make_user_summary_output(user)
        "#{user.name.bold.light_green} (@#{user.screen_name}) #{user.verified ? '*'.bold.light_blue : ''}\n" +
        "Description:".bold + " #{user.description || 'No description'}\n" +
        "Location:".bold + " #{user.location || 'Unknown'}\n" +
        "Followers:".bold + " #{user.followers_count} | " +
        "Following:".bold + " #{user.friends_count} | " +
        "Listed:".bold + " #{user.listed_count} | " +
        "Favorites:".bold + " #{user.favorites_count} | " +
        "Statuses:".bold + " #{user.statuses_count}\n"
      end

      # Output a user summary to the console
      #
      # @param user [Birdwatcher::Models::User]
      def output_user_summary(user)
        make_user_summary_output(user)
      end

      # Make user details output
      #
      # @param user [Birdwatcher::Models::User]
      #
      # @return [String] summary and details about a user
      def make_user_details_output(user)
        "#{user.name.bold.light_green} (@#{user.screen_name}) #{user.verified ? '*'.bold.light_blue : ''}\n\n" +

        "Description:".bold + " #{user.description || 'No description'}\n" +
        "   Location:".bold + " #{user.location || 'Unknown'}\n" +
        "    Website:".bold + " #{user.url || 'None'}\n" +
        "   Timezone:".bold + " #{user.timezone}\n" +
        "   Language:".bold + " #{user.lang}\n\n" +

        "Followers:".bold + " #{user.followers_count}\n" +
        "Following:".bold + " #{user.friends_count}\n" +
        "Favorites:".bold + " #{user.favorites_count}\n" +
        " Statuses:".bold + " #{user.statuses_count}\n\n" +

        "  Added:".bold + " #{time_ago_in_words(user.created_at)}\n" +
        "Updated:".bold + (user.updated_at ? " #{time_ago_in_words(user.updated_at)}" : " Never") + "\n"
      end

      # Output user details to the console
      #
      # @param user [Birdwatcher::Models::User]
      def output_user_details(user)
        output make_user_details_output(user)
      end

      # Make status summary output
      #
      # @param status [Birdwatcher::Models::Status]
      #
      # @return [String] short summary of status
      def make_status_summary_output(status)
        "#{status.user.name.bold.light_green} (@#{status.user.screen_name}) #{status.user.verified ? '*'.bold.light_blue : ''} #{status.posted_at.strftime('%b %e, %H:%M')}\n" +
        "#{status.text.bold}\n" +
        "#{'Favorites:'.light_blue} #{status.favorite_count} | " +
        "#{'Retweets:'.light_blue} #{status.retweet_count}\n"
      end

      # Output status summary to the console
      #
      # @param status [Birdwatcher::Models::Status]
      def output_status_summary(status)
        output make_status_summary_output(status)
      end

      # Make URL summary output
      #
      # @param url [Hash]
      # @return [String] URL summary
      def make_url_summary_output(url)
        out  = "#{(url[:final_url] || url[:url]).bold}\n" +
               "#{'Shares:'.bold} #{url[:count]}\n"
        out += "#{'Title:'.bold} #{url[:title] || 'Unknown'}\n"
        if url[:http_status]
          case url[:http_status]
          when 200..299
            status = url[:http_status].to_s.bold.light_green
          when 400..499
            status = url[:http_status].to_s.bold.light_yellow
          when 500..599
            status = url[:http_status].to_s.bold.light_red
          else
            status = url[:http_status].to_s.bold
          end
          out += "#{'Status Code:'.bold} #{status}\n"
        else
          out += "#{'Status Code:'.bold} Unknown\n"
        end
        out += "#{'Content Type:'.bold} #{url[:content_type] || 'Unknown'}\n"
        out
      end

      # Page potentially long output to the console
      #
      # @param text [String] Text to page
      #
      # If the text is long, it will be automatically paged with the system's
      # currently configured pager command (usually `less`).
      def page_text(text)
        ::TTY::Pager::SystemPager.new.page(text)
      rescue Errno::EPIPE
      end
    end
  end
end
