# Sources describe where feedback originates.
# source_type distinguishes real integrations from synthetic stub services.
# adapter_key is the programmatic identifier used by the ingestion pipeline.
class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      # source_type: 0=real, 1=synthetic
      t.integer :source_type, null: false, default: 0
      t.string :adapter_key, null: false
      t.jsonb :config, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :sources, :adapter_key, unique: true
    add_index :sources, :source_type
    add_index :sources, :active
  end
end
