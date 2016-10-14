Sequel.migration do
  change do
    create_table(:klout_topics_users) do
      foreign_key :user_id, :users, :on_delete => :cascade, :index => true
      foreign_key :klout_topic_id, :klout_topics, :on_delete => :cascade, :index => true
    end
  end
end
