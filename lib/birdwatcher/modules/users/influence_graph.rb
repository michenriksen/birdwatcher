module Birdwatcher
  module Modules
    module Users
      class InfluenceGraph < Birdwatcher::Module
        self.meta = {
          :name        => "Influence Graph",
          :description => "Graphs the influence between users from Klout",
          :author      => "Michael Henriksen <michenriksen@neomailbox.ch>",
          :options     => {
            "DEST" => {
              :value       => nil,
              :description => "Destination file",
              :required    => true
            },
            "USERS" => {
              :value       => nil,
              :description => "Space-separated list of screen names (all users if empty)",
              :required    => false
            },
            "FORMAT" => {
              :value       => "png",
              :description => "Destination file format (any format supported by Graphviz)",
              :required    => true
            }
          }
        }

        def self.info
<<-INFO
The Influence Graph module generates an influence graph between users in the
currently active workspace. The graph can be used to identify who each user is
being influenced by as well as who each user influences.

The influence information is retrieved by the #{'users/klout_influence'.bold} so
be sure to run that module before running this one.

The generated graph is in PNG format.
INFO
        end

        def run
          if !GraphViz::Constants::FORMATS.include?(option_setting("FORMAT"))
            error("Unsupported format: #{option_setting('FORMAT').bold}")
            return false
          end
          if screen_names = option_setting("USERS")
            users = current_workspace.users_dataset
              .where("screen_name IN ?", screen_names.split(" ").map(&:strip))
              .order(:screen_name)
              .eager(:influencers, :influencees)
          else
            users = current_workspace.users_dataset.order(:screen_name).eager(:influencers, :influencees)
          end
          if users.empty?
            error("There are no users to process")
            return false
          end
          graph = GraphViz.new(:G, :type => :digraph)
          users_in_workspace = current_workspace.users.map(&:screen_name)
          nodes = {}
          influences = {}
          users.each do |user|
            influences[user.screen_name] ||= []
            influences[user.screen_name] += user.influencees.select { |i| users_in_workspace.include?(i.screen_name) }.map(&:screen_name)
            user.influencers.select { |i| users_in_workspace.include?(i.screen_name) }.map(&:screen_name).each do |influencer|
              influences[influencer] ||= []
              influences[influencer] << user.screen_name unless influences[influencer].include?(user.screen_name)
            end
          end
          influences.each_pair do |user, influence|
            influence.uniq!
            next if influence.empty?
            nodes[user] ||= graph.add_nodes(user)
            influence.each do |influencee|
              if influences[influencee] && influences[influencee].include?(user)
                direction = "both"
                influences[influencee].delete(user)
              else
                direction = "forward"
              end
              nodes[influencee] ||= graph.add_nodes(influencee)
              graph.add_edges(nodes[user], nodes[influencee], :color => "lightblue", :fontcolor => "cornflowerblue", :dir => direction, :arrowhead => "normal")
            end
          end
          task("Outputting graph...") do
            graph.output(option_setting("FORMAT") => option_setting("DEST"))
          end
          info("Graph written to #{option_setting('DEST').bold}")
        end
      end
    end
  end
end
