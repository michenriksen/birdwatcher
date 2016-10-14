module Birdwatcher
  module Modules
    module Users
      class KloutInfluence < Birdwatcher::Module
        self.meta = {
          :name        => "User Klout Influence",
          :description => "Enrich users with their Klout influence",
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
The User Klout Influence module can be used to gather an influence graph of all
users in the currently active workspace. The Klout Influence API can tell who
users are being influenced by as well as who they are influencing.

The influence graph can be generated with the #{'users/influence_graph'.bold} module
when the raw data has been gathered with this module.

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
          threads          = thread_pool(option_setting("THREADS").to_i)
          influencer_mutex = Mutex.new
          influencee_mutex = Mutex.new
          users.each do |user|
            threads.process do
              begin
                if influence = klout_client.get_influence(user.klout_id)
                  influence[:influencers].each do |screen_name|
                    db_influencer = influencer_mutex.synchronize do
                      Birdwatcher::Models::Influencer.find_or_create(:workspace_id => current_workspace.id, :screen_name => screen_name)
                    end
                    if !user.influencers.include?(db_influencer)
                      user.add_influencer(db_influencer)
                    end
                  end
                  influence[:influencees].each do |screen_name|
                    db_influencee = influencee_mutex.synchronize do
                      Birdwatcher::Models::Influencee.find_or_create(:workspace_id => current_workspace.id, :screen_name => screen_name)
                    end
                    if !user.influencees.include?(db_influencee)
                      user.add_influencee(db_influencee)
                    end
                  end
                  info("User #{user.screen_name.bold} is influenced by: #{influence[:influencers].map(&:bold).join(', ')}")
                  info("User #{user.screen_name.bold} is influencing: #{influence[:influencees].map(&:bold).join(', ')}")
                else
                  error("Could not get Klout influence for #{user.screen_name.bold}")
                end
                user.save
              rescue => e
                error("Processing of #{user.screen_name.bold} failed (#{e.class})")
                info(e.backtrace.join("\n"))
              end
            end
          end
          threads.shutdown
        end
      end
    end
  end
end
