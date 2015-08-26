class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :title
      t.string :year, limit: 4
      t.string :imdb_id
      t.timestamps
    end
  end
end
