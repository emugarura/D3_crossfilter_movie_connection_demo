# encoding: UTF-8

class DirectingWorker
  include Sidekiq::Worker
  
  def perform(movie_id, directing_info)
    directing_info = HashWithIndifferentAccess.new(directing_info)
    
    puts directing_info.inspect
    
    movie = Movie.find(movie_id)
    
    unless person = Person.find_by_imdb_id(directing_info[:imdb_id])
      person_data = PersonCrawler.get_person(directing_info[:imdb_id])
      person = Person.create_with(person_data).find_or_create_by(imdb_id: directing_info[:imdb_id])
      sleep(1)
    end
    
    movie.directings.create(person_id: person.id)
  end
end