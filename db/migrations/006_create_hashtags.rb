Sequel.migration do
  change do
    create_table(:hashtags) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :tag, :index => true
      DateTime :updated_at
      DateTime :created_at, :index => true
    end
  end
end
