# encoding: UTF-8

class PersonCrawler
  
  def self.agent
    @@agent ||= self.initialize_agent
    return @@agent
  end
  
  def self.initialize_agent
    a = Mechanize.new
    a.user_agent_alias = 'Mac Safari'
    return a
  end
  
  def self.get_person(imdb_id)
    doc = self.person_data(imdb_id)
    
    name = doc.at('h1.header').at("span[itemprop='name']").inner_html.strip
    name = name.gsub(/^(.*)\s+(\<.*?\>.*?\<\/.*?\>)?$/, "\\1")
    
    return {imdb_id: imdb_id, name: name}
  end
  
  def self.person_data(imdb_id, options={})
    options[:force] ||= false
    
    person_filename = File.join cache_path, "#{imdb_id}.html.gz"
    
    doc = Nokogiri::HTML.parse(person_filename)
    
    if !File.exist?(person_filename) || File.size(person_filename)==35 || options[:force]
      # puts "live"
      doc = agent.get("http://akas.imdb.com/name/#{imdb_id}")
      GzFile.open(person_filename) do |f|
        f.write doc.parser.to_s
      end
    else
      # puts "cache"
      doc = Nokogiri::HTML.parse(GzFile.read(person_filename))
    end
    return doc
  end

private
  def self.cache_path
    "/Users/christoph/Sites/rails_apps/sdokb_cache/people/"
    # File.join Rails.root, "tmp/cache/imdb/people/"
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
