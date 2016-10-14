module Birdwatcher
  module Modules
    module Urls
      class MostShared < Birdwatcher::Module
        self.meta = {
          :name        => "Most Shared URLs",
          :description => "Lists shared URLs ordered from most to least shared",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "USERS" => {
              :value       => nil,
              :description => "Space-separated list of screen names (all users if empty)",
              :required    => false
            },
            "MIN_SHARE_COUNT" => {
              :value       => 2,
              :description => "Exclude URLS shared fewer times than specified",
              :required    => false
            },
            "SINCE" => {
              :value       => nil,
              :description => "List URLs shared since specified time (last 7 days if empty)",
              :required    => false
            },
            "BEFORE" => {
              :value       => nil,
              :description => "List URLs shared before specified time (from now if empty)",
              :required    => false
            }
          }
        }

         def self.info
<<-INFO
The Most Shared URLs module can show a simple list of shared URLs ordered from
most to least shared. If a URL has been shared by several people, it is a good
indication that it has important or interesting information.

To enhance the functionality of this module, it is recommended to run the
#{'urls/crawl'.bold} module first in order to get information on the URLs such
as HTTP status codes, content types and page titles. If the information is
available, this module will display it.
INFO
        end

        def run
          if option_setting("SINCE")
            since = parse_time(option_setting("SINCE")).strftime("%Y-%m-%d")
          else
            since = (Date.today - 7).strftime("%Y-%m-%d")
          end
          if option_setting("BEFORE")
            before = parse_time(option_setting("BEFORE")).strftime("%Y-%m-%d")
          else
            before = Time.now.strftime("%Y-%m-%d")
          end
          if option_setting("USERS")
            user_ids = current_workspace.users_dataset.where("screen_name IN ?", option_setting("USERS").split(" ").map(&:strip)).map(&:id)
            urls = database["SELECT urls.url, urls.final_url, urls.title, urls.http_status, urls.content_type, count(statuses_urls.*) AS count
              FROM urls
              INNER JOIN statuses_urls
                ON statuses_urls.url_id = urls.id
              INNER JOIN statuses
                ON statuses_urls.status_id = statuses.id
              WHERE statuses.user_id IN ?
              AND statuses.workspace_id = ?
              AND DATE(statuses.posted_at) <= DATE(?)
              AND DATE(statuses.posted_at) >= DATE(?)
              GROUP BY urls.url, urls.final_url, urls.title, urls.http_status, urls.content_type
              ORDER BY count DESC", user_ids, current_workspace.id, since, before].all
          else
            urls = database["SELECT urls.url, urls.final_url, urls.title, urls.http_status, urls.content_type, count(statuses_urls.*) AS count
              FROM urls
              INNER JOIN statuses_urls
                ON statuses_urls.url_id = urls.id
              INNER JOIN statuses
                ON statuses_urls.status_id = statuses.id
              WHERE statuses.workspace_id = ?
              AND DATE(statuses.posted_at) <= DATE(?)
              AND DATE(statuses.posted_at) >= DATE(?)
              GROUP BY urls.url, urls.final_url, urls.title, urls.http_status, urls.content_type
              ORDER BY count DESC", current_workspace.id, before, since].all
          end
          if urls.count.zero?
            error("There are no URLs to display")
            return false
          end
          text = ""
          urls.each do |url|
            next if option_setting("MIN_SHARE_COUNT") && url[:count] <= option_setting("MIN_SHARE_COUNT")
            text += make_url_summary_output(url) + "\n#{Birdwatcher::Console::LINE_SEPARATOR}\n\n"
          end
          page_text(text)
        end
      end
    end
  end
end
