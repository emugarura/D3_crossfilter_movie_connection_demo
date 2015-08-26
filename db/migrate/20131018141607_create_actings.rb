class CreateActings < ActiveRecord::Migration
  def change
    create_table :actings do |t|
      t.integer :person_id
      t.integer :movie_id
      
      t.string :role
      
      t.timestamps
    end
  end
end
