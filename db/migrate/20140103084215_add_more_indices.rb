class AddMoreIndices < ActiveRecord::Migration
  def change
    
    add_index :people, :imdb_id
    add_index :movies, :imdb_id
    
  end
end
