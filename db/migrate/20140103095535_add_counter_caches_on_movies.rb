class AddCounterCachesOnMovies < ActiveRecord::Migration
  def change
    add_column :movies, :actors_count, :integer, default: 0
    add_column :movies, :directors_count, :integer, default: 0
    
    add_index :movies, :actors_count
    add_index :movies, :directors_count
  end
end
