class AddIndexOnActings < ActiveRecord::Migration
  def change
    add_index :actings, [:person_id, :movie_id], unique: true
    add_index :actings, :movie_id
    
    add_index :directings, [:person_id, :movie_id], unique: true
    add_index :directings, :movie_id
  end
end
