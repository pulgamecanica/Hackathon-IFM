# Loyalty accounts are filtering metadata only — no transaction ledger.
# Decision: NO loyalty_transactions table. Points are display-only denorms.
# tier: 0=none, 1=bronze, 2=silver, 3=gold, 4=platinum
class CreateLoyaltyAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :loyalty_accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :program_name, null: false
      # tier: 0=none, 1=bronze, 2=silver, 3=gold, 4=platinum
      t.integer :tier, null: false, default: 0
      t.integer :points_balance, null: false, default: 0
      t.integer :lifetime_points, null: false, default: 0
      t.datetime :enrolled_at

      t.timestamps
    end

    add_index :loyalty_accounts, :tier
    add_index :loyalty_accounts, :program_name
  end
end
