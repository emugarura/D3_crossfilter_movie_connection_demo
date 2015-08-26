# encoding: UTF-8

class MovieCastWorker
  include Sidekiq::Worker
  
  sidekiq_options :queue => :movie_cast
  
  def perform(imdb_id, movie_id)
    movie = Movie.find(movie_id)
    
    MovieCrawler.get_movie_directors(imdb_id).each do |directing_info|
      if person = Person.find_by_imdb_id(directing_info[:imdb_id])
        movie.directings.create(person_id: person.id)
      else
        DirectingWorker.perform_async movie.id, directing_info
      end
    end
    
    MovieCrawler.get_movie_cast(imdb_id).each do |acting_info|
      if person = Person.find_by_imdb_id(acting_info[:imdb_id])
        movie.actings.create(person_id: person.id, role: acting_info[:character_name])
      else
        ActingWorker.perform_async movie.id, acting_info
      end
    end
    sleep(1)
  end
end
