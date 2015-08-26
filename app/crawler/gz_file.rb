require 'zlib'

class GzFile
  
  def self.open(path, &block)
    Zlib::GzipWriter.open(path) do |gz|
      yield gz
    end
  end
  
  def self.read(path)
    data = nil
    
    File.open(path) do |f|
      gz = Zlib::GzipReader.new(f)
      data = gz.read
      gz.close
    end
    
    return data
  end
  
end