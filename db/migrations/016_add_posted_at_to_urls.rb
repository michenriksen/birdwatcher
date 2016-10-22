Sequel.migration do
  up do
    alter_table(:urls) do
      add_column :posted_at, DateTime
      add_index :posted_at
    end
  end

  down do
    alter_table(:urls) do
      drop_column :posted_at
    end
  end
end
