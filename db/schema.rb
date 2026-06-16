# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_16_101809) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_insights", force: :cascade do |t|
    t.decimal "confidence", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.text "key_themes"
    t.string "language_detected", limit: 10
    t.string "model_version", null: false
    t.bigint "raw_feedback_id", null: false
    t.integer "sentiment"
    t.decimal "sentiment_score", precision: 5, scale: 4
    t.text "summary"
    t.boolean "synthetic", default: false, null: false
    t.jsonb "topics", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["generated_at"], name: "index_ai_insights_on_generated_at"
    t.index ["raw_feedback_id"], name: "index_ai_insights_on_raw_feedback_id", unique: true
    t.index ["sentiment"], name: "index_ai_insights_on_sentiment"
    t.index ["synthetic"], name: "index_ai_insights_on_synthetic"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "external_identifiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "identifiable_id", null: false
    t.string "identifiable_type", null: false
    t.string "issued_by"
    t.string "scheme", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["identifiable_type", "identifiable_id"], name: "index_external_identifiers_on_identifiable"
    t.index ["scheme", "value"], name: "index_external_identifiers_on_scheme_and_value", unique: true
    t.index ["scheme"], name: "index_external_identifiers_on_scheme"
  end

  create_table "locations", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "country_code", limit: 2
    t.datetime "created_at", null: false
    t.decimal "lat", precision: 10, scale: 7
    t.integer "location_type", default: 0, null: false
    t.decimal "long", precision: 10, scale: 7
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_locations_on_country_code"
    t.index ["location_type"], name: "index_locations_on_location_type"
  end

  create_table "loyalty_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "enrolled_at"
    t.integer "lifetime_points", default: 0, null: false
    t.integer "points_balance", default: 0, null: false
    t.string "program_name", null: false
    t.integer "tier", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["program_name"], name: "index_loyalty_accounts_on_program_name"
    t.index ["tier"], name: "index_loyalty_accounts_on_tier"
    t.index ["user_id"], name: "index_loyalty_accounts_on_user_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "price_cents"
    t.string "sku", null: false
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["status"], name: "index_products_on_status"
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "purchase_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "external_transaction_id"
    t.bigint "location_id"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "product_id", null: false
    t.datetime "purchased_at", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "source_id"
    t.boolean "synthetic", default: false, null: false
    t.integer "unit_price_cents"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_transaction_id"], name: "index_purchase_data_on_external_transaction_id"
    t.index ["location_id"], name: "index_purchase_data_on_location_id"
    t.index ["product_id", "purchased_at"], name: "index_purchase_data_on_product_id_and_purchased_at"
    t.index ["product_id"], name: "index_purchase_data_on_product_id"
    t.index ["purchased_at"], name: "index_purchase_data_on_purchased_at"
    t.index ["source_id"], name: "index_purchase_data_on_source_id"
    t.index ["synthetic"], name: "index_purchase_data_on_synthetic"
    t.index ["user_id", "purchased_at"], name: "index_purchase_data_on_user_id_and_purchased_at"
    t.index ["user_id"], name: "index_purchase_data_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "ai_insight_id", null: false
    t.datetime "created_at", null: false
    t.integer "dimension", default: 0, null: false
    t.bigint "product_id", null: false
    t.datetime "rated_at", null: false
    t.decimal "score", precision: 4, scale: 2, null: false
    t.boolean "synthetic", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["ai_insight_id", "product_id", "dimension"], name: "idx_ratings_insight_product_dimension", unique: true
    t.index ["ai_insight_id"], name: "index_ratings_on_ai_insight_id"
    t.index ["product_id", "dimension"], name: "index_ratings_on_product_id_and_dimension"
    t.index ["product_id"], name: "index_ratings_on_product_id"
    t.index ["rated_at"], name: "index_ratings_on_rated_at"
    t.index ["score"], name: "index_ratings_on_score"
    t.index ["synthetic"], name: "index_ratings_on_synthetic"
  end

  create_table "raw_feedback_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_id", null: false
    t.bigint "raw_feedback_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_raw_feedback_products_on_product_id"
    t.index ["raw_feedback_id", "position"], name: "index_raw_feedback_products_on_raw_feedback_id_and_position"
    t.index ["raw_feedback_id", "product_id"], name: "idx_raw_feedback_products_unique", unique: true
    t.index ["raw_feedback_id"], name: "index_raw_feedback_products_on_raw_feedback_id"
  end

  create_table "raw_feedbacks", force: :cascade do |t|
    t.integer "channel", default: 0, null: false
    t.string "checksum", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "feedback_content_type", default: 0, null: false
    t.string "language", limit: 10
    t.bigint "location_id"
    t.jsonb "metadata", default: {}, null: false
    t.integer "processing_status", default: 0, null: false
    t.bigint "purchase_data_id"
    t.bigint "source_id", null: false
    t.datetime "submitted_at"
    t.boolean "synthetic", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["channel"], name: "index_raw_feedbacks_on_channel"
    t.index ["checksum"], name: "index_raw_feedbacks_on_checksum", unique: true
    t.index ["location_id"], name: "index_raw_feedbacks_on_location_id"
    t.index ["processing_status"], name: "index_raw_feedbacks_on_processing_status"
    t.index ["purchase_data_id"], name: "index_raw_feedbacks_on_purchase_data_id"
    t.index ["source_id", "submitted_at"], name: "index_raw_feedbacks_on_source_id_and_submitted_at"
    t.index ["source_id"], name: "index_raw_feedbacks_on_source_id"
    t.index ["submitted_at"], name: "index_raw_feedbacks_on_submitted_at"
    t.index ["synthetic"], name: "index_raw_feedbacks_on_synthetic"
    t.index ["user_id"], name: "index_raw_feedbacks_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "adapter_key", null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "source_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_sources_on_active"
    t.index ["adapter_key"], name: "index_sources_on_adapter_key", unique: true
    t.index ["source_type"], name: "index_sources_on_source_type"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_type", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["slug"], name: "index_vendors_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_insights", "raw_feedbacks"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "loyalty_accounts", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "vendors"
  add_foreign_key "purchase_data", "locations"
  add_foreign_key "purchase_data", "products"
  add_foreign_key "purchase_data", "sources"
  add_foreign_key "purchase_data", "users"
  add_foreign_key "ratings", "ai_insights"
  add_foreign_key "ratings", "products"
  add_foreign_key "raw_feedback_products", "products"
  add_foreign_key "raw_feedback_products", "raw_feedbacks"
  add_foreign_key "raw_feedbacks", "locations"
  add_foreign_key "raw_feedbacks", "purchase_data", column: "purchase_data_id"
  add_foreign_key "raw_feedbacks", "sources"
  add_foreign_key "raw_feedbacks", "users"
end
