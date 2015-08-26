class CreateDirectings < ActiveRecord::Migration
  def change
    create_table :directings do |t|
      t.integer :person_id
      t.integer :movie_id
      t.timestamps
    end
    
    add_index :directings, [:person_id, :movie_id]
    add_index :directings, :movie_id
  end
end
