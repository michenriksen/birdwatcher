module Birdwatcher
  module Commands
    class User < Birdwatcher::Command
      self.meta = {
        :description => "Manage users",
        :names       => %w(user users),
        :usage       => "user [ACTION]"
      }

      def self.detailed_usage
<<-USAGE
The #{'user'.bold} command manipulates users in the current workspace.

#{'USAGE:'.bold}

#{'List all users in the workspace:'.bold}
  user list

#{'Add one or more users to the workspace:'.bold}
  user create [USER1[ USER2 ... USERN]]

#{'Update information on one or more users:'.bold}
  user update [USER1[ USER2 ... USERN]]

#{'Delete one or more users from the workspace:'.bold}
  user delete [USER1[ USER2 ... USERN]]
USAGE
      end

      def run
        if !arguments?
          error("You must provide an action")
          return false
        end
        action = arguments.first.downcase
        case action
        when "list"
          list_users
        when "create", "add", "-a"
          create_users
        when "update", "-u"
          update_users
        when "delete", "destroy", "rm", "-d"
          delete_users
        else
          list_user
        end
      end

      private

      def list_users
        if current_workspace.users.count.zero?
          info("There are currently no users in this workspace")
          return true
        end
        newline
        users = current_workspace.users_dataset.order(:screen_name).map do |u|
          make_user_summary_output(u)
        end.join("\n#{Birdwatcher::Console::LINE_SEPARATOR}\n\n")
        page_text(users)
      end

      def list_user
        if !user = current_workspace.users_dataset.first(:screen_name => arguments.first)
          error("User #{screen_name.bold} was not found in workspace")
          return false
        end
        newline
        output_user_details(user)
        newline
      end

      def create_users
        screen_names = arguments[1..-1].uniq
        if screen_names.empty?
          error("You must provide at least one screen name")
          return false
        end
        screen_names.each do |screen_name|
          begin
            if current_workspace.users_dataset.first(:screen_name => screen_name)
              error("User #{screen_name.bold} is already in the workspace")
              next
            end
            api_user = twitter_client.user(screen_name)
            save_user(api_user)
            info("Added #{screen_name.bold} to workspace")
          rescue Twitter::Error::NotFound
            error("There is no user with screen name: #{screen_name.bold}")
          end
        end
      end

      def update_users
        screen_names = arguments[1..-1].uniq
        if screen_names.empty?
          db_users = current_workspace.users
        else
          db_users = current_workspace.users_dataset.where("screen_name IN ?", screen_names)
        end
        threads = thread_pool
        db_users.each do |db_user|
          threads.process do
            begin
              api_user = twitter_client.user(db_user.screen_name)
              db_user.update(
                :name              => api_user.name,
                :location          => api_user.location,
                :description       => api_user.description,
                :url               => (api_user.website_urls.first ? api_user.website_urls.first.expanded_url.to_s : nil),
                :profile_image_url => api_user.profile_image_url_https.to_s,
                :followers_count   => api_user.followers_count,
                :friends_count     => api_user.friends_count,
                :listed_count      => api_user.listed_count,
                :favorites_count   => api_user.favorites_count,
                :statuses_count    => api_user.statuses_count,
                :utc_offset        => api_user.utc_offset,
                :timezone          => api_user.time_zone,
                :geo_enabled       => api_user.geo_enabled?,
                :verified          => api_user.verified?,
                :lang              => api_user.lang
              )
              info("Updated information for #{db_user.screen_name.bold}")
            rescue Twitter::Error::NotFound
              error("There is no user with screen name: #{db_user.screen_name.bold}")
            end
          end
        end
        threads.shutdown
      end

      def delete_users
        screen_names = arguments[1..-1].uniq
        if screen_names.empty?
          error("You must provide at least one screen name")
          return false
        end
        return unless confirm("Are you sure you want to delete #{screen_names.map(&:bold).join(', ')} and all associated data?")
        screen_names.each do |screen_name|
          begin
            if !db_user = current_workspace.users_dataset.first(:screen_name => screen_name)
              error("User #{screen_name.bold} was not found in workspace")
              next
            end
            db_user.destroy
            info("Deleted #{screen_name.bold} from workspace")
          rescue Twitter::Error::NotFound
            error("There is no user with screen name: #{screen_name.bold}")
          end
        end
      end
    end
  end
end
