Sequel.migration do
  change do
    create_table(:mentions) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :twitter_id, :index => true
      String :screen_name, :index => true
      String :name
      DateTime :updated_at
      DateTime :created_at, :index => true
    end
  end
end
