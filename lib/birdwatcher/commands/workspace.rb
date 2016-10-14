module Birdwatcher
  module Commands
    class Workspace < Birdwatcher::Command
      self.meta = {
        :description => "Manage workspaces",
        :names       => %w(workspace workspaces),
        :usage       => "workspace [ACTION]"
      }

      def self.detailed_usage
<<-USAGE
Workspaces enable you to segment and manage users and data stored in the database.
You can use workspaces to create logical separation between different users.
For example, you may want to create a workspace for a company, a department or
for a specific topic.

There will always be a default workspace with the name #{Birdwatcher::Models::Workspace::DEFAULT_WORKSPACE_NAME.bold} which might be enough
if you plan to use Birdwatcher for a small group of Twitter users.

#{'USAGE:'.bold}

#{'List available workspaces:'.bold}
  workspace list

#{'Create a new workspace:'.bold}
  workspace create NAME [DESCRIPTION]

#{'Switch to a workspace:'.bold}
  workspace use NAME

#{'Delete a workspace:'.bold}
  workspace delete NAME

#{'Rename a workspace'.bold}
  workspace rename NAME NEW_NAME
USAGE
      end

      def run
        if !arguments?
          info("Current workspace: #{current_workspace.name.bold} (database ID: #{current_workspace.id.to_s.bold})")
          return true
        end
        action = arguments.first.downcase
        case action
        when "list"
          list_workspaces
        when "create", "add", "-a"
          create_workspace
        when "rename", "-r"
          rename_workspace
        when "select", "use"
          select_workspace
        when "delete", "destroy", "rm", "-d"
          delete_workspace
        else
          select_workspace(arguments.first)
        end
      end

      def list_workspaces
        longest_workspace_name = Birdwatcher::Models::Workspace.all.map(&:name).max_by(&:length)
        info("Available workspaces:\n")
        Birdwatcher::Models::Workspace.order(:name).each do |workspace|
          if current_workspace.id == workspace.id
            workspace_name = "*".bold.light_green + "  #{workspace.name}"
          else
            workspace_name = "   #{workspace.name}"
          end

          output_formatted(" %-#{longest_workspace_name.bold.length}s  \t\t%s\n", workspace_name.bold, workspace.description)
        end
        newline
      end

      def select_workspace(name = nil)
        name ||= arguments[1]

        if !name
          error("You must provide a workspace name")
          return false
        end

        if workspace = Birdwatcher::Models::Workspace.first(:name => name)
          self.current_workspace = workspace
          info("Now using workspace: #{workspace.name.bold}")
        else
          error("There is no workspace with that name")
        end
      end

      def create_workspace
        name        = arguments[1]
        description = arguments[2..-1].to_a.join(" ")
        description = nil unless description

        if !name
          error("You must provide a workspace name")
          return false
        end

        if Birdwatcher::Models::Workspace.first(:name => name)
          error("There is already a workspace with that name")
          return false
        end

        workspace = Birdwatcher::Models::Workspace.create(
          :name        => name,
          :description => description
        )

        info("Created workspace: #{workspace.name.bold}")
        self.current_workspace = workspace
      end

      def rename_workspace
        old_name = arguments[1]
        new_name = arguments[2]

        if !old_name || !new_name
          error("You must provide workspace name and new name")
          return false
        end

        if old_name == Birdwatcher::Models::Workspace::DEFAULT_WORKSPACE_NAME
          error("Default workspace cannot be renamed")
          return false
        end

        if !old_workspace = Birdwatcher::Models::Workspace.first(:name => old_name)
          error("There is no workspace named #{old_name.bold}")
          return false
        end

        if Birdwatcher::Models::Workspace.first(:name => new_name)
          error("There is already a workspace named #{new_name.bold}")
          return false
        end

        old_workspace.update(:name => new_name)
        if old_workspace.id == current_workspace.id
          self.current_workspace = old_workspace
        end

        info("Workspace #{old_name.bold} renamed to #{new_name.bold}")
      end

      def delete_workspace
        name = arguments[1]

        if !name
          error("You must provide a workspace name")
          return false
        end

        if workspace = Birdwatcher::Models::Workspace.first(:name => name)
          return unless confirm("Are you sure you want to delete #{name.bold} and all associated data?")
          workspace.destroy
          info("Deleted workspace: #{workspace.name.bold}")
          if workspace.default_workspace?
            self.current_workspace = Birdwatcher::Models::Workspace.create_default_workspace!
            return
          end
          if current_workspace.id == workspace.id
            self.current_workspace = Birdwatcher::Models::Workspace.first(
              :name => Birdwatcher::Models::Workspace::DEFAULT_WORKSPACE_NAME
            )
          end
        else
          error("There is no workspace with that name")
          return false
        end
      end
    end
  end
end
