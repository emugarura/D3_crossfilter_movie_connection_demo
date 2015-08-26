# encoding: UTF-8

class ActingWorker
  include Sidekiq::Worker
  
  def perform(movie_id, acting_info)
    acting_info = HashWithIndifferentAccess.new(acting_info)
    
    puts acting_info.inspect
    
    movie = Movie.find(movie_id)
    
    unless person = Person.find_by_imdb_id(acting_info[:imdb_id])
      person_data = PersonCrawler.get_person(acting_info[:imdb_id])
      person = Person.create_with(person_data).find_or_create_by(imdb_id: acting_info[:imdb_id])
      sleep(1)
    end
    
    movie.actings.create(person_id: person.id, role: acting_info[:character_name])
  end
end