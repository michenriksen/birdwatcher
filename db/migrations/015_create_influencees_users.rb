Sequel.migration do
  change do
    create_table(:influencees_users) do
      foreign_key :user_id, :users, :on_delete => :cascade, :index => true
      foreign_key :influencee_id, :influencees, :on_delete => :cascade, :index => true
    end
  end
end
