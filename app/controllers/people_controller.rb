class PeopleController < ApplicationController
  
  def index
    @people = Person.limit(30).all
  end
  
  def show
    @person = Person.includes(:acted_movies).find(params[:id])
    @actings = @person.actings.includes(:movie).order('movies.year DESC')
  end
  
end
