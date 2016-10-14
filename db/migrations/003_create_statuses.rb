Sequel.migration do
  change do
    create_table(:statuses) do
      primary_key :id
      foreign_key :workspace_id, :workspaces, :on_delete => :cascade, :index => true
      foreign_key :user_id, :users, :on_delete => :cascade, :index => true
      String :twitter_id, :index => true
      String :text, :index => true
      String :source
      Boolean :retweet, :index => true
      Boolean :geo, :index => true
      String :longitude
      String :latitude
      String :place_type
      String :place_name
      String :place_country_code
      String :place_country
      Integer :favorite_count, :index => true
      Integer :retweet_count, :index => true
      String :sentiment, :index => true
      Boolean :possibly_sensitive, :index => true
      String :lang, :index => true
      DateTime :posted_at, :index => true
      DateTime :updated_at, :index => true
      DateTime :created_at, :index => true
    end
  end
end
