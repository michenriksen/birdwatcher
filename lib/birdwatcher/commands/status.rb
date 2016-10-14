module Birdwatcher
  module Commands
    class Status < Birdwatcher::Command
      self.meta = {
        :description => "Manage statuses",
        :names       => %w(status statuses tweet tweets),
        :usage       => "status [ACTION]"
      }

      def self.detailed_usage
<<-USAGE
The #{'status'.bold} command manipulates statuses in the current workspace.

#{'USAGE:'.bold}

#{'List the last 1000 statuses from all users:'.bold}
  status list

#{'List the last 1000 statuses from specific users:'.bold}
  status list [USER1[ USER2 ... USERN]]

#{'Fetch and process new statuses from all users:'.bold}
  status fetch

#{'Search all statuses for a specific word:'.bold}
  status search SEARCHTERM
USAGE
      end

      def run
        if !arguments?
          error("You must provide an action")
          return false
        end
        action = arguments.first.downcase
        case action
        when "list", "-l", "show", "-s"
          list_statuses(arguments[1..-1])
        when "search", "-s", "find"
          search_statuses
        when "fetch", "-f", "update", "-u"
          fetch_statuses
        else
          list_statuses(arguments)
        end
      end

      private

      def fetch_statuses
        current_workspace.users_dataset.order(:screen_name).each do |user|
          statuses = []
          task("Fetching statuses for #{user.screen_name.bold}...") do
            statuses = get_statuses_for_user(user)
          end
          task("Processing #{Birdwatcher::Util.pluralize(statuses.count, 'status', 'statuses')}...") do
            threads = thread_pool
            statuses.each do |status|
              threads.process do
                save_status(status, user)
              end
            end
            threads.shutdown
          end
        end
      end

      def search_statuses
        search_term = arguments[1..-1].join(" ")
        if search_term.empty?
          error("You must provide a search term")
          return false
        end
        statuses = current_workspace.statuses_dataset
          .where("text LIKE ?", "%#{search_term}%")
          .order(Sequel.desc(:posted_at))
          .eager(:user)
          .limit(1000)
        texts = statuses.map { |s| make_status_summary_output(s) }.join("\n#{Birdwatcher::Console::LINE_SEPARATOR}\n\n")
        page_text(texts)
      end

      def list_statuses(screen_names = nil)
        if screen_names.nil? || screen_names.empty?
          statuses = current_workspace.statuses_dataset.order(Sequel.desc(:posted_at)).eager(:user).limit(1000)
        else
          user_ids = current_workspace.users_dataset.where("screen_name IN ?", screen_names).map(:id)
          statuses = current_workspace.statuses_dataset.where("user_id IN ?", user_ids).order(Sequel.desc(:posted_at)).eager(:user).limit(1000)
        end
        texts = statuses.map { |s| make_status_summary_output(s) }.join("\n#{Birdwatcher::Console::LINE_SEPARATOR}\n\n")
        page_text(texts)
      end

      def collect_with_max_id(collection = [], max_id = nil, pages = 5, &block)
        return collection.flatten if pages.zero?
        response = yield(max_id)
        collection += response
        response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, pages - 1, &block)
      end

      def get_statuses_for_user(user)
        if last_status = user.statuses_dataset.order(Sequel.desc(:posted_at)).first
          since_id = last_status.twitter_id
        end
        collect_with_max_id do |max_id|
          options = {:count => 200, :include_rts => true}
          options[:since_id] = since_id unless since_id.nil?
          options[:max_id]   = max_id unless max_id.nil?
          twitter_client.user_timeline(user.screen_name, options)
        end
      end
    end
  end
end
