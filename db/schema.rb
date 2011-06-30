# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110630212458) do

  create_table "asset_outputs", :force => true do |t|
    t.integer  "asset_id",    :null => false
    t.integer  "output_id",   :null => false
    t.string   "fingerprint"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width"
    t.integer  "height"
  end

  create_table "assets", :force => true do |t|
    t.string   "idkey",                                    :null => false
    t.string   "title"
    t.string   "description"
    t.string   "owner"
    t.string   "url"
    t.integer  "creator_id",         :default => 1,        :null => false
    t.text     "notes"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.string   "image_copyright"
    t.string   "image_fingerprint"
    t.string   "image_title"
    t.string   "image_description"
    t.datetime "image_updated_at"
    t.string   "image_gravity",      :default => "center", :null => false
    t.integer  "image_width"
    t.integer  "image_height"
    t.integer  "image_file_size"
    t.integer  "image_version"
    t.datetime "image_taken"
    t.integer  "native_id"
    t.string   "native_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "outputs", :force => true do |t|
    t.integer  "site_package_id",                    :null => false
    t.string   "code",                               :null => false
    t.string   "size",                               :null => false
    t.string   "extension",                          :null => false
    t.boolean  "is_rich",         :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "prerender",       :default => false, :null => false
  end

  create_table "site_packages", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "url"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                              :default => "",    :null => false
    t.string   "encrypted_password",  :limit => 128, :default => "",    :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "username",                                              :null => false
    t.boolean  "is_admin",                           :default => false, :null => false
    t.integer  "default_site_id",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
