Sequel.migration do
  change do
    create_table(:hashtags_statuses) do
      foreign_key :hashtag_id, :hashtags, :on_delete => :cascade, :index => true
      foreign_key :status_id, :statuses, :on_delete => :cascade, :index => true
    end
  end
end
