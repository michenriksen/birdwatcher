module Birdwatcher
  module Modules
    module Users
      class SocialGraph < Birdwatcher::Module
        self.meta = {
          :name        => "Social Graph",
          :description => "Graphs the social relations between users",
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
            "MIN_WEIGHT" => {
              :value       => 10,
              :description => "Percentage of the highest edge weight to be considered minimum edge weight",
              :required    => true
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
The Social Graph module generates an undirected graph between users in the
currently active workspace. The edges between users will be weighted by simply
counting the amount of times they mutually mention each other in statuses. The
module can identify social clusters within the collection of users.

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
          else
            users = current_workspace.users_dataset.order(:screen_name)
          end
          if users.empty?
            error("There are no users to process")
            return false
          end
          graph = GraphViz.new(:G, :type => :graph, :use => "sfdp", :overlap => "prism", :splines => "curved")
          edge_weights = {}
          highest_edge_weight = 0
          nodes = {}
          users.each do |user|
            task("Calculating social graph for #{user.screen_name.bold}...") do
              users.each do |other_user|
                next if user.id == other_user.id
                edge_weights[user.screen_name] ||= {}
                edge_weights[other_user.screen_name] ||= {}
                next if (edge_weights[user.screen_name].key?(other_user.screen_name) && edge_weights[other_user.screen_name].key?(user.screen_name))
                edge_weights[user.screen_name][other_user.screen_name] = user.statuses_dataset.where("text LIKE ?", "%#{other_user.screen_name}%").count
                edge_weights[other_user.screen_name][user.screen_name] = other_user.statuses_dataset.where("text LIKE ?", "%#{user.screen_name}%").count
                total_edge_weight = edge_weights[user.screen_name][other_user.screen_name] + edge_weights[other_user.screen_name][user.screen_name]
                highest_edge_weight = total_edge_weight if (total_edge_weight > highest_edge_weight)
              end
            end
          end
          task("Generating social graph...") do
            edge_weights.each_pair do |user, user_graph|
              user_graph.each_pair do |other_user, edge_weight|
                total_edge_weight = edge_weight + edge_weights[other_user][user]
                percentage = (total_edge_weight.to_f / highest_edge_weight.to_f * 100).to_i
                if percentage >= option_setting("MIN_WEIGHT").to_i
                  nodes[user] ||= graph.add_nodes(user)
                  nodes[other_user] ||= graph.add_nodes(other_user)
                  case percentage
                  when 0..25
                    pen_width = 1
                  when 26..50
                    pen_width = 2
                  when 51..75
                    pen_width = 4
                  when 76..100
                    pen_width = 5
                  end
                  graph.add_edges(nodes[user], nodes[other_user], :weight => total_edge_weight, :penwidth => pen_width, :color => "lightblue", :fontcolor => "cornflowerblue", :label => total_edge_weight.to_s)
                  edge_weights[other_user].delete(user)
                end
              end
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
