class Directing < ActiveRecord::Base
  
  validates_presence_of :person_id, :movie_id
  
  belongs_to :person
  belongs_to :movie, counter_cache: :directors_count
  
  validates_uniqueness_of :person_id, scope: :movie_id
  
  # include Neoid::Relationship
  # neoidable do |c|
  #   c.relationship start_node: :person, end_node: :movie, type: :directs
  #   c.relationship start_node: :person, end_node: :movie, type: :is_part_of
  # end
  
end
