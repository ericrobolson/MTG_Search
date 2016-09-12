# Eric Olson (c) 2016

require 'sqlite3'
require 'json'

DATABASE_LOCATION = '../databases/'
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'


class Artist
	@id
	@name
	
	def initialize(name)
		@name = name
	end
	
	def name
		return @name
	end
	
	def to_json
		if @id == nil
			@id = "123"
		end
		return '"id":"' + @id + "\", \"name\":\"" + @name + "\"}"
	end
end 

blah = {:id => "123", :name => "Bob"}
blah2 = {:id=>"234", :name=>"bill"}



a1 = Artist.new("blah")

blah1n2 = {:c1 => blah, :c2 => blah2, :c3 => a1.to_json}
puts blah1n2.to_json
