# encoding: UTF-8

class MovieInformationWorker
  include Sidekiq::Worker
  
  sidekiq_options :queue => :movie_cast
  
  def perform(imdb_id)
    movie_info = MovieCrawler.get_movie_information(imdb_id)
    movie = Movie.create_with(movie_info).find_or_create_by(imdb_id: imdb_id)
    MovieCastWorker.perform_async imdb_id, movie.id
    sleep(1)
  end
end