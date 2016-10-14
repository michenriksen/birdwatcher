Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      String :twitter_id, :index => true
      String :screen_name, :index => true
      String :name
      String :location
      String :description
      String :url
      String :profile_image_url
      Integer :followers_count, :index => true
      Integer :friends_count, :index => true
      Integer :listed_count, :index => true
      Integer :favorites_count, :index => true
      Integer :statuses_count, :index => true
      Integer :utc_offset
      String :timezone
      Boolean :geo_enabled, :index => true
      Boolean :verified, :index => true
      String :lang, :index => true
      String :klout_id
      Integer :klout_score, :index => true
      DateTime :updated_at, :index => true
      DateTime :created_at, :index => true
    end
  end
end
