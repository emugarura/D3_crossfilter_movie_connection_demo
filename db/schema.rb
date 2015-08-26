# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140103184450) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actings", force: true do |t|
    t.integer  "person_id"
    t.integer  "movie_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "actings", ["movie_id"], name: "index_actings_on_movie_id", using: :btree
  add_index "actings", ["person_id", "movie_id"], name: "index_actings_on_person_id_and_movie_id", unique: true, using: :btree

  create_table "directings", force: true do |t|
    t.integer  "person_id"
    t.integer  "movie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "directings", ["movie_id"], name: "index_directings_on_movie_id", using: :btree
  add_index "directings", ["person_id", "movie_id"], name: "index_directings_on_person_id_and_movie_id", unique: true, using: :btree

  create_table "movies", force: true do |t|
    t.string   "title"
    t.string   "year",            limit: 4
    t.string   "imdb_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "actors_count",              default: 0
    t.integer  "directors_count",           default: 0
  end

  add_index "movies", ["actors_count"], name: "index_movies_on_actors_count", using: :btree
  add_index "movies", ["directors_count"], name: "index_movies_on_directors_count", using: :btree
  add_index "movies", ["imdb_id"], name: "index_movies_on_imdb_id", unique: true, using: :btree

  create_table "people", force: true do |t|
    t.string   "name"
    t.string   "imdb_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "people", ["imdb_id"], name: "index_people_on_imdb_id", unique: true, using: :btree

end
