Sequel.migration do
  change do
    create_table(:influencers_users) do
      foreign_key :user_id, :users, :on_delete => :cascade, :index => true
      foreign_key :influencer_id, :influencers, :on_delete => :cascade, :index => true
    end
  end
end
