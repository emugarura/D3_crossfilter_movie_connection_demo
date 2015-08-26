# encoding: UTF-8

class FilmographyScannerWorker
  include Sidekiq::Worker
  
  sidekiq_options :queue => :filmography
  
  def perform(imdb_id)
    imdb_id = imdb_id.pop
    
    doc = PersonCrawler.person_data(imdb_id)

    f = doc.at('#filmography')

    if f && (f.at('div[data-category="actor"]') || f.at('div[data-category="actress"]'))
      div_pos = nil

      i = 0
      f.search('div.head').each do |r|
        if r['data-category']=='actor' || r['data-category']=='actress'
          div_pos = i
        end

        i+=1
      end

      if div_pos
        row_bodies = f.search('div.filmo-category-section')
        if row_bodies.length > 0
          actor_rows = row_bodies[div_pos].search('div.filmo-row')
        else
          actor_rows = []
        end
      end

      if actor_rows.length > 0
        movie = {}
        actor_rows.each do |row|

          # Ignore TV-Series
          next if row.to_s.match(/.*\s+\(TV\s+Series\).*/)
          next if row.to_s.match(/.*\s+\(Video\s+Game\).*/)
          
          if row.at('b/a')
            movie[:title] = row.at('b/a').inner_text.strip
            movie[:imdb_id] = row.at('b/a')['href'].gsub(/.*\/(tt[^\/]+).*/, "\\1")

            # Ignore movies we already found
            next if File.read('/Users/christoph/Desktop/found_imdb_ids.txt').split(/\n/).include? movie[:imdb_id]
          end

          if row.at('.year_column')
            movie[:year] = row.at('.year_column').inner_text.gsub(/.*(\d{4}).*/m, "\\1").to_i
          end
          
          if movie[:imdb_id]
            File.open('/Users/christoph/Desktop/found_imdb_ids.txt', 'a'){|f| f.write("#{movie[:imdb_id]}\n")}
            
            if movie[:year] >= 2000
              puts movie.inspect
              MovieInformationWorker.perform_async movie[:imdb_id]
            end
          else
            raise "IMdB ID not found!"
          end
        end
      end

    end
    
  end
end