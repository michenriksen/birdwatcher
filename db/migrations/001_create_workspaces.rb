Sequel.migration do
  change do
    create_table(:workspaces) do
      primary_key :id
      String :name, :index => true, :unique => true
      String :description
      DateTime :updated_at
      DateTime :created_at
    end
  end
end
