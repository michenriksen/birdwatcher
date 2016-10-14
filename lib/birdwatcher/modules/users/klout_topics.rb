module Birdwatcher
  module Modules
    module Users
      class KloutTopics < Birdwatcher::Module
        self.meta = {
          :name        => "User Klout Topics",
          :description => "Enrich users with their Klout topics",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "THREADS" => {
              :value       => 5,
              :description => "Number of concurrent threads",
              :required    => false
            }
          }
        }

        def self.info
<<-INFO
The User Klout Topics module can be used to retrieve the general topics that
users in the currently active workspace are tweeting about.

#{'Note:'.bold} This module requires that users have been enriched with their
Klout ID from the #{'users/klout_id'.bold} module. It also requires that Birdwatcher has
been configured with one or more Klout API keys in order to work.
INFO
        end

        def run
          if !klout_client
            error("Birdwatcher has not been configured with any Klout API keys")
            return false
          end
          users = current_workspace.users_dataset.where("klout_id IS NOT NULL").order(:screen_name)
          if users.empty?
            error("There are no users with Klout IDs")
            return false
          end
          threads = thread_pool(option_setting("THREADS").to_i)
          mutex   = Mutex.new
          users.each do |user|
            threads.process do
              begin
                if klout_topics = klout_client.get_topics(user.klout_id)
                  if klout_topics.empty?
                    warn("User #{user.screen_name.bold} has no topics; skipping")
                    next
                  end
                  klout_topics.each do |topic|
                    db_topic = mutex.synchronize do
                      Birdwatcher::Models::KloutTopic.find_or_create(:workspace_id => current_workspace.id, :topic => topic)
                    end
                    if !user.klout_topics.include?(db_topic)
                      user.add_klout_topic(db_topic)
                    end
                  end
                  info("User #{user.screen_name.bold} has topics: #{klout_topics.map(&:bold).join(', ')}")
                else
                  error("Could not get Klout topics for #{user.screen_name.bold}")
                end
                user.save
              rescue => e
                error("Processing of #{user.screen_name.bold} failed (#{e.class})")
              end
            end
          end
          threads.shutdown
        end
      end
    end
  end
end
