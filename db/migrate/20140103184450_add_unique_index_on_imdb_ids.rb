class AddUniqueIndexOnImdbIds < ActiveRecord::Migration
  def change
    remove_index :people, :imdb_id
    remove_index :movies, :imdb_id
    
    add_index :people, :imdb_id, unique: true
    add_index :movies, :imdb_id, unique: true
  end
end
