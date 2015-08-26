class MoviesController < ApplicationController
  
  def index
    if params[:term] && params[:term].length > 2
      @movies = Movie.where('title ilike ?', "%#{params[:term]}%").limit(20).order('title')
    else
      @movies = Movie.limit(20).order('title').all
    end
    respond_to do |format|
      format.html
      format.json { render json: @movies }
    end
  end
  
  def relations
    @movie1 = Movie.find(params[:movie1_id])
    @movie2 = Movie.find(params[:movie2_id])
    
    max_degrees = 6
    found_connections = 0
    exclude_people = []
    @connections = []
    
    Timeout::timeout(20) do
    
      degree = 0
      while (degree < max_degrees && found_connections <= 0)
        new_connections = Movie.connection.query(build_pg_query(degree+1, exclude_people, {
          start_year: params[:start_year].to_i,
          end_year:   params[:end_year].to_i,
          max_nodes:  params[:max_nodes].to_i
        }))
      
        exclude_people += new_connections.map{|c| c[degree*2]}.uniq
        found_connections += new_connections.length
      
        @connections << new_connections
        degree += 1
      end
    
    end
    
    people_ids = []
    movie_ids  = []
    nodes = []
    @layers = []
    @edges = {}
    
    @connections.each_with_index do |conn, degree|
      conn.each do |row|
        hops = [@movie1.id.to_s, @movie1.year] + row
        
        i=0
        while i <= row.length-3
          from = hops[i]
          to   = hops[i+3]
          key  = Digest::MD5.hexdigest("#{from}#{to}")
          
          @edges[key] ||= {}
          @edges[key][:source] = from
          @edges[key][:target] = to
          @edges[key][:actors] ||= []
          @edges[key][:weight] ||= 0
          
          unless @edges[key][:actors].include? hops[i+1]
            @edges[key][:actors] << hops[i+1]
            @edges[key][:weight] += 1
          end
          
          @layers[i/3] ||= {}
          @layers[i/3][:nodes] ||= []
          @layers[i/3][:nodes] << to unless @layers[i/3][:nodes].include?(to)
          
          people_ids << hops[i+1]
          movie_ids  << from << to
          
          i += 3
        end
      end
    end
    
    people = Person.find(people_ids.uniq)
    movies = Movie.includes(:directors).find(movie_ids.uniq)
    @layers.each{|l| l[:nodes].map!{|id| movies.detect{|m| m.id.to_s==id}}}
    @layers = [{nodes: [@movie1]}] + @layers

    @edges = @edges.values
    @edges.each do |edge|
      edge[:actors].map!{|aid| people.detect{|p| p.id.to_s==aid}}
    end
    
    @response = {
      layers: @layers,
      links: @edges
    }
    
    respond_to do |format|
      format.html { redirect_to movies_path }
      format.json do
        render json: @response, callback: params[:callback]
      end
    end
  rescue Timeout::Error
    respond_to do |format|
      format.html { redirect_to movies_path }
      format.json do
        render json: {layers: [], links: []}, callback: params[:callback]
      end
    end
  end
  
  def build_pg_query(degrees, exclude_people=[], options={})
    options[:start_year] ||= 1900
    options[:end_year]   ||= 2017
    options[:max_nodes]  ||= 10
    
    if options[:start_year]<1900
      options[:start_year] = 1900
    elsif options[:start_year]>2017
      options[:start_year] = 2017
    end
    
    if options[:end_year]<1900
      options[:end_year] = 2017
    elsif options[:end_year]>2017
      options[:end_year] = 2017
    end
    
    if options[:max_nodes]<1
      options[:max_nodes] = 10
    elsif options[:max_nodes]>10
      options[:max_nodes] = 10
    end
    
    sql = "SELECT "
    sql << 1.upto(degrees).map{|i| "person_hop_#{i}.person_id, movie_hop_#{i}.movie_id, movie_hop_#{i}_movie.year"}.join(', ')
    sql << "\nFROM movies AS source \n"
    sql << "LEFT JOIN actings AS person_hop_1 ON person_hop_1.movie_id=source.id\n"
    sql << "LEFT JOIN actings AS movie_hop_1 ON movie_hop_1.person_id=person_hop_1.person_id\n"
    sql << "LEFT JOIN movies AS movie_hop_1_movie ON movie_hop_1.movie_id=movie_hop_1_movie.id\n"
    2.upto(degrees).each do |i|
      sql << "LEFT JOIN actings AS person_hop_#{i} ON person_hop_#{i}.movie_id=movie_hop_#{i-1}.movie_id\n"
      sql << "LEFT JOIN actings AS movie_hop_#{i}  ON movie_hop_#{i}.person_id=person_hop_#{i}.person_id\n"
      sql << "LEFT JOIN movies AS movie_hop_#{i}_movie ON movie_hop_#{i}.movie_id=movie_hop_#{i}_movie.id\n"
    end
    sql << "WHERE source.id=#{@movie1.id}\n"
    1.upto(degrees).each do |i|
      sql << "AND (movie_hop_#{i}_movie.year BETWEEN '#{options[:start_year]}' AND '#{options[:end_year]}')\n"
    end
    sql << "AND movie_hop_1.movie_id<>source.id\n"
    
    # exclude previous hops -------------------------------------------------
    2.upto(degrees).each do |i|
      (i-1).downto(1).each do |j|
        sql << " AND movie_hop_#{i}.movie_id<>movie_hop_#{j}.movie_id\n"
      end
    end
    # look for the target movie ---------------------------------------------
    sql << "AND (\n"
    sql << " " + 1.upto(degrees).map{|i| "movie_hop_#{i}.movie_id=#{@movie2.id}"}.join(' OR ')
    sql << "\n)\n"
    
    # prevent loops by excluding people ---------------------------------------
    if exclude_people.length > 0
      1.upto(degrees-1) do |i|
        sql << "AND person_hop_#{i}.person_id NOT IN (#{exclude_people.join(', ')})\n"
      end
    end
    
    sql << "ORDER BY " << 1.upto(degrees).map{|i| "movie_hop_#{i}.movie_id"}.join(', ')
    sql << "\nLIMIT #{options[:max_nodes]}"
    sql << ";\n"
    
    return sql
  end
  
  def show
    @movie = Movie.includes(:actors).find(params[:id])
  end
  
end
