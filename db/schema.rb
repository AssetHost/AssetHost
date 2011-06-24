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

ActiveRecord::Schema.define(:version => 20110624153719) do

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
    t.datetime "image_updated_at"
    t.boolean  "image_processing",   :default => false
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
    t.integer  "site_package_id",                   :null => false
    t.string   "code",                              :null => false
    t.string   "size",                              :null => false
    t.string   "extension",                         :null => false
    t.boolean  "is_rich",         :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "site_packages", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "url"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
