Sequel.migration do
  change do
    create_table(:klout_topics) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :topic, :index => true
      DateTime :created_at, :index => true
    end
  end
end
