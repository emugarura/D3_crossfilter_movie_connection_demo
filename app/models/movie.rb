class Movie < ActiveRecord::Base
  
  validates_presence_of :title, :imdb_id, :year
  validates_uniqueness_of :imdb_id
  
  has_many :actings, dependent: :destroy
  has_many :actors, through: :actings, source: :person
  
  has_many :directings, dependent: :destroy
  has_many :directors, through: :directings, source: :person
  
  # include Neoid::Node
  
end
