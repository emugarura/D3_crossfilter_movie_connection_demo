# encoding: UTF-8

class MovieCrawler
  
  def self.agent
    @@agent ||= self.initialize_agent
    return @@agent
  end
  
  def self.initialize_agent
    a = Mechanize.new
    a.user_agent_alias = 'Mac Safari'
    return a
  end
  
  def self.get_movie_directors(imdb_id)
    doc = self.movie_cast(imdb_id)
    
    directings = []
    
    dir_as = doc.search("div#fullcredits_content").search('a').select{|a| a['href'].match(/.*ttfc_fc_dr\d+.*/)}
    
    if dir_as
      dir_as.each do |a|
        begin
        
          imdb_id = a['href'].gsub(/.*\/name\/(nm\d+)\/.*/, "\\1")
          
          directings << {imdb_id: imdb_id}
        rescue Exception => e
          puts "Error with movie #{self.id}:"
          puts e
          puts row
        end
      end
    end
    
    return directings
  end
  
  def self.get_movie_cast(imdb_id)
    doc = self.movie_cast(imdb_id)
    
    cast = []
    
    cast_rows = ((doc/'table.cast_list')/'tr')
    
    cast_rows.each do |row|
      begin
        name_link = row.search('a').detect{|a| !a.at('span[itemprop="name"]').nil?}
        next if name_link.nil?
        
        name = name_link.at('span[itemprop="name"]').inner_html.strip
        
        imdb_id = name_link['href'].gsub(/.*(nm\d+).*/i, "\\1")
        
        role_td = (row/'td.character/div')
        if role_link = (role_td/'a').first
          role = role_link
        else
          role = role_td
        end
        
        role = role.inner_html.strip.gsub(/[\r\n]/, " ").squeeze(" ")
        
        name = fix_encoding(name)
        role = fix_encoding(role)
        
        cast << {
          :imdb_id        => imdb_id,
          :credited_as    => name,
          :character_name => role
        }
      end
    end
    
    return cast
  end
  
  def self.get_movie_information(imdb_id)
    doc = self.movie_data(imdb_id)
    
    data = {}
    
    title = doc.at('h1.header')
    if (title / '.title-extra').length > 0
      data[:title] = (title / '.title-extra').children.first.text.strip.gsub(/\A"(.*)"\z/, "\\1")
      year = (title.at('.nobr/a') || title.at('.nobr')).inner_text.strip
      data[:year]  = year.gsub(/[\(\)]/, "")
    elsif (title / '.itemprop').detect{|s| s['itemprop']=='name'}
      data[:title] = (title / '.itemprop').detect{|s| s['itemprop']=='name'}.inner_text.strip
      year = (title.at('.nobr/a') || title.at('.nobr')).inner_text.strip
      data[:year]  = year.gsub(/[\(\)]/, "")
    else
      data[:title] = title.children.first.inner_text.strip
      data[:year]  = (title / 'span/a').first.inner_text.strip
    end
    
    data[:imdb_id] = imdb_id.strip
    
    return data
  end
  
  def self.movie_cast(imdb_id, options={})
    options[:force] ||= false
    
    cast_filename  = File.join cache_path, "cast/#{imdb_id}_cast.html.gz"
    
    if !File.exist?(cast_filename) || File.size(cast_filename)==0 || options[:force]
      puts "live"
      doc = agent.get("http://akas.imdb.com/title/#{imdb_id}/fullcredits")
      write_cached_file(cast_filename, doc.body)
    else
      puts "cached"
      doc = Nokogiri::HTML.parse(read_cached_file(cast_filename))
    end
    return doc
  end
  
  def self.movie_data(imdb_id, options={})
    options[:force] ||= false
    
    movie_filename = File.join cache_path, "info/#{imdb_id}_movie.html.gz"
    
    if !File.exist?(movie_filename) || File.size(movie_filename)==0 || options[:force]
      puts "live"
      doc = agent.get("http://akas.imdb.com/title/#{imdb_id}")
      write_cached_file(movie_filename, doc.body)
    else
      puts "cached"
      doc = Nokogiri::HTML.parse(read_cached_file(movie_filename))
    end
    return doc
  end
  
private

  def self.cache_path
    "/Users/christoph/Sites/rails_apps/sdokb_cache/movies/"
    # File.join Rails.root, "tmp/cache/imdb/movies/"
  end
  
  def self.write_cached_file(path, content)
    GzFile.open(path) do |f|
      f.write content
    end
  end
  
  def self.read_cached_file(path)
    GzFile.read(path)
  end
  
  def self.fix_encoding(str)
    return if str.nil? || str.strip==""
    if str.respond_to?(:encode)
      str.encode('UTF-8')
    else
      Iconv.iconv('ISO-8859-1', 'UTF-8', str).first.to_s
    end
  end

end
