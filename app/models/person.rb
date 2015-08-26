class Person < ActiveRecord::Base
  
  validates_presence_of :name, :imdb_id
  validates_uniqueness_of :imdb_id
  
  has_many :actings, dependent: :destroy
  has_many :acted_movies, through: :actings, source: :movie
  
  has_many :directings, dependent: :destroy
  has_many :directed_movies, through: :directings, source: :movie
  
  # include Neoid::Node
  
end
