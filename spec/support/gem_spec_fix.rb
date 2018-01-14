module Gem
  def self.source_index
    sources
  end

  def self.cache
    sources
  end

  SourceIndex = Specification

  class SourceList
    # If you want vendor gems, this is where to start writing code.
    def search( *args ); []; end
    def each( &block ); end
    include Enumerable
  end
end
