Sequel.migration do
  change do
    create_table(:statuses_urls) do
      foreign_key :url_id, :urls, :on_delete => :cascade, :index => true
      foreign_key :status_id, :statuses, :on_delete => :cascade, :index => true
    end
  end
end
