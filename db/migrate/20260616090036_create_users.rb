# Users are internal "collection developers" — no auth columns by design.
# Decision: no password_digest, no sessions, no tokens. This is intentional.
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      # user_type: 0=customer, 1=staff, 2=synthetic
      # Integer-backed enum: fast filtering, compact storage, easy to extend.
      t.integer :user_type, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :user_type
  end
end
