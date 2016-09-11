require 'sqlite3'



def searchCards()
	database_location = 'databases/'
	cardDb = database_location + 'Card.db'

	searchCardName = false
	searchColorIdentity = false
	searchText = false
	searchArtist = false
	searchLayout = false
	searchOriginalText = false
	searchOriginalType = false
	searchRarity = false
	searchType = false
	searchTypes = false
	searchSetId = false
	searchCmc = false
	searchPower = false
	searchToughness = false
	
	cardName = ""
	colorIdentity = ""
	text = ""
	artist = "" 
	layout = "" 
	originalText = "" 
	originalType = "" 
	rarity = "" 
	type = "" 
	types = "" 
	setId = "" 
	cmc = ""
	
	SQLite3::Database.open(cardDb) do |db|
		puts db.execute("
			SELECT
				distinct Name
			FROM 
				Card
			WHERE
				Color like 'Black' AND CardId NOT IN
				()
			GROUP BY
				Name, color
			HAVING
				Color like 'Black'
				
		")
		
		
		#	db.execute("
		#		--DECLARE 
		#		--	@searchCardName BIT = ?, @cardName TEXT = ?,			-- commaDelimitedList
		#		--	@searchColorIdentity BIT = ?, @colorIdentity TEXT = ?,	-- commaDelimitedList
		#		--	@searchText BIT = ?, @text TEXT = ?,					-- commaDelimitedList
		#		--	@searchArtist BIT = ?, @artist TEXT = ?,				-- commaDelimitedList
		#		--	@searchLayout BIT = ?, @layout TEXT = ?,				-- commaDelimitedList
		#		--	@searchOriginalText BIT = ?, @originalText TEXT = ?,	-- commaDelimitedList
		#		--	@searchOriginalType BIT = ?, @originalType TEXT = ?,	-- commaDelimitedList
		#		--	@searchRarity BIT = ?, @rarity TEXT = ?, 				-- commaDelimitedList
		#		--	@searchType BIT = ?, @type TEXT = ?,   					-- commaDelimitedList
		#		--	@searchTypes BIT = ?, @types TEXT = ?, 					-- commaDelimitedList
		#		--	@searchSetId BIT = ?, @setId TEXT = ?, 					-- commaDelimitedList
		#		--	@searchCmc BIT = ?, @cmc TEXT = ?						-- commaDelimitedList
		#	
		#		SELECT
		#			DISTINCT 
		#				Name,
		#				CMC,
		#				Rarity,
		#				Text
		#		FROM
		#			Card
		#		--WHERE
		#		--	--((@searchCardName = 1 AND Name like @cardName) OR @searchCardName = 0) AND
		#			
		#			
		#		ORDER BY 
		#			Name
		#	",[
		#		searchCardName, cardName,
		#		searchColorIdentity, colorIdentity,
		#		searchText, text,
		#		searchArtist, artist,
		#		searchLayout, layout,
		#		searchOriginalText, originalText,
		#		searchOriginalType, originalType,
		#		searchRarity, rarity,
		#		searchType, type,
		#		searchTypes, types,
		#		searchSetId, setId,
		#		searchCmc, cmc
		#		]
		#	)

	end
end


searchCards()