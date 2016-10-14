Sequel.migration do
  change do
    create_table(:influencees) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :screen_name, :index => true
      DateTime :created_at, :index => true
    end
  end
end
