# Classifies each insight into one of the three feedback points the business
# tracks: product, distribution, visibility (Decision: 3 focus areas).
class AddFocusToAiInsights < ActiveRecord::Migration[8.1]
  def change
    # focus: 0=product, 1=distribution, 2=visibility
    add_column :ai_insights, :focus, :integer, default: 0, null: false
    add_index :ai_insights, :focus
  end
end
