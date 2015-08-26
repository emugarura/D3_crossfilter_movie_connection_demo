class Acting < ActiveRecord::Base
  
  validates_presence_of :person_id, :movie_id
  
  belongs_to :person
  belongs_to :movie, counter_cache: :actors_count
  
  validates_uniqueness_of :person_id, scope: :movie_id
  
  # include Neoid::Relationship
  # neoidable do |c|
  #   c.relationship start_node: :person, end_node: :movie, type: :acts_in
  #   c.relationship start_node: :person, end_node: :movie, type: :is_part_of
  # end
  
end
