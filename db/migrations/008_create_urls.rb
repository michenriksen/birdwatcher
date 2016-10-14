Sequel.migration do
  change do
    create_table(:urls) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :url, :index => true
      String :final_url, :index => true
      Integer :http_status, :index => true
      String :content_type, :index => true
      String :title, :index => true
      DateTime :crawled_at, :index => true
      DateTime :updated_at, :index => true
      DateTime :created_at, :index => true
    end
  end
end
