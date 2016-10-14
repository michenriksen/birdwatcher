module Birdwatcher
  module Modules
    module Users
      class KloutId < Birdwatcher::Module
        self.meta = {
          :name        => "User Klout IDs",
          :description => "Enrich users with their Klout ID",
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
The User Klout IDs module can populate the current workspace's users with their
Klout ID. Having a Klout ID on users makes it possible to gather information
with other modules such as #{'users/klout_influence'.bold}, #{'users/klout_topics'.bold} and
#{'users/klout_score'.bold}.

#{'Note:'.bold} Birdwatcher must be configured with one or more Klout API keys
in order to work.
INFO
        end

        def run
          if !klout_client
            error("Birdwatcher has not been configured with any Klout API keys")
            return false
          end
          users = current_workspace.users_dataset.order(:screen_name)
          if users.empty?
            error("There are no users to process")
            return false
          end
          threads = thread_pool(option_setting("THREADS").to_i)
          users.each do |user|
            threads.process do
              begin
                klout_id = klout_client.get_id(user.screen_name)
                if klout_id.nil?
                  warn("User #{user.screen_name.bold} doesn't have a Klout ID; skipping")
                  next
                end
                user.klout_id = klout_id
                user.save
                info("User #{user.screen_name.bold} has a Klout ID: #{klout_id.to_s.bold}")
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
