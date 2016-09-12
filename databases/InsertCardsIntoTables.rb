# Eric Olson (c) 2016
# Parse the JSON file containing infomation about 
# the Magic The Gathering cards into databases

require 'JSON'
require 'sqlite3'
DATABASE_LOCATION = ''
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'
	
#####################################
# Insert the card into the database #
#####################################

# Insert a card into the database or update it if it already exists
#	db: the database connection to use
#	setId: the id for the set that the card belongs to
#	card: a json object used from MTGJson containing card information
def InsertCard(db, setId, card)
	name = card["name"]
	text = card["text"]
	cmc = card["cmc"]
	power = card["power"]
	toughness = card["toughness"]
	number = card["number"]
	id = card["id"]
				
	# create the card if it doesn't exist
	if (GetCardId(db, setId, name, id).length == 0)
		artistId = GetValueId(db, "Artist", "ArtistId", "Artist", card["artist"])
		rarityId = GetValueId(db, "Rarity", "RarityId", "Rarity", card["rarity"])
		layoutId = GetValueId(db, "Layout", "LayoutId", "Layout", card["layout"])
		
		db.execute("
			INSERT INTO Card
			(
				Name,
				Text,
				CMC,
				Power,
				Toughness,
				SetId,
				Number,
				Id,
				ArtistId,
				RarityId,
				LayoutId
			)
			VALUES
			(
				?,	-- Name,
				?,	-- Text,
				?,	-- CMC,
				?,	-- Power,
				?,	-- Toughness,
				?,	-- SetId,
				?,	-- Number,
				?,	-- Id
				?,	-- ArtistId
				?,	-- RarityId
				?	-- LayoutId
			);",
			[
				name,
				text,
				cmc,
				power,
				toughness,
				setId,
				number,
				id,
				artistId,
				rarityId,
				layoutId
			])
	end
	
	cardId = GetCardId(db, setId, name, id)
		
	# build the linking tables
	InsertLinks(db, card["colors"], "CardColor", cardId, "Color", "ColorId", "Color")
	InsertLinks(db, card["types"], "CardType", cardId, "Type", "TypeId", "Type")
	InsertLinks(db, card["supertypes"], "CardSupertype", cardId, "Supertype", "SupertypeId", "Supertype")
	InsertLinks(db, card["subtypes"], "CardSubtype", cardId, "Subtype", "SubtypeId", "Subtype")
	
	puts "SetId: " + setId[0].to_s + "; CardId: " + cardId[0].to_s + "; " + name
end

# Get the CardId for the card with the given information
#	db: the database connection to use
#	setId: the setId for the card
#	id: the generated id for the card; it's a unique hash for that cards values and the set
def GetCardId(db, setId, name, id)
	return db.execute("
		SELECT
			CardId 
		FROM 
			Card
		WHERE
			Name = ? AND SetId = ? AND Id = ?
		;",[
			name, 
			setId,
			id,		
		])
end

#################################################################################################
# Create the linking tables for Colors, Types, Subtypes, Supertypes, Artists, Rarity and Layout #
#################################################################################################

# Return the Id from the table with the selected value if it exists. Insert value if it doesn't exist, then return the Id
#	db: the database connection to use
#	valueTable: the table which contains the value that is wanted
#	idColumn: the column for the value table which contains the id of the item that is wanted
#	valueColumn: the column that contains the value of the item that is wanted
#	value:	the value that is wanted
def GetValueId(db, valueTable, idColumn, valueColumn, value)
	query = db.execute("SELECT " + idColumn + " FROM " + valueTable + " WHERE " + valueColumn + " = ?;",[value])
	
	if (query.length == 1)
		return query
	else
		db.execute("INSERT INTO " + valueTable + "(" + valueColumn + ") VALUES (?);", [value])
		return db.execute("SELECT " + idColumn + " FROM " + valueTable + " WHERE " + valueColumn + " = ?;",[value])
	end
end

# Check linking table value
#	db: the database connection to use
#	linkingTable: the linking table to check
#	valueIdColumn: the column which contains the value table's id
#	valueId: the id for the value
#	cardId: the id for the card the link is for
def LinkingTableValueExists(db, linkingTable, valueIdColumn, valueId, cardId)
	exists = db.execute("SELECT " + valueIdColumn.to_s + " FROM " + linkingTable + " WHERE CardId = ? AND " + valueIdColumn + " = ?;", [cardId, valueId])	
	return exists.length != 0
end

# Create a link between the card and the value.
#	linkValues: the values to create links for
#	linkingTable: the name of the linking table
#	cardId: the card to insert the link for
#	valueTable: the table that contains the value to use in the linking table
#	valueIdColumn: the column that contains the id of the value table and the column for it in the linking table
#	valueColumn: the column that contains the value we need to check for in the value table to see if it exists; if not, we insert the value into the value table
def InsertLinks(db, linkValues, linkingTable, cardId, valueTable, valueIdColumn, valueColumn)
	if (linkValues == nil)
		return
	end
	
	linkValues.each do |linkValue|
		linkValueId = GetValueId(db, valueTable, valueIdColumn, valueColumn, linkValue.to_s)
		
		if (!LinkingTableValueExists(db, linkingTable, valueIdColumn, linkValueId, cardId))
			db.execute("INSERT INTO " + linkingTable + "(" + valueIdColumn +", CardId) VALUES (?,?);", [linkValueId, cardId])
		end
	end
end


########################################################
# Insert the data into the database from the JSON file #
########################################################

puts "\n\nStarting..."
puts "\n\n...\n\n"

json = File.read('../rescources/AllSets-x.json')

createdSets = 0
createdCards = 0

allSets = JSON.parse(json)
SQLite3::Database.open(cardInformationDb) do |db|
	allSets.each do |set|
		
		setId = -1
			
		# Attempt to insert the set
		db.execute("
			INSERT OR IGNORE INTO CardSet 
					(Name, Code, ReleaseDate, Border, Type, Booster)
			VALUES 	(?, 	?, 		?, 			?, 		?,		?)",[
				set[1]['name'].to_s, 
				set[1]['code'].to_s,
				set[1]['releaseDate'].to_s,
				set[1]['border'].to_s,
				set[1]['type'].to_s,
				set[1]['booster'].to_s
			])
		
		# Grab the setId
		setId = 
			db.execute("
				SELECT SetId FROM CardSet
				WHERE Name = ? AND
				CODE = ? AND
				ReleaseDate = ? AND
				Border = ? AND
				TYPE = ? AND
				Booster = ?", [
				set[1]['name'].to_s, 
				set[1]['code'].to_s,
				set[1]['releaseDate'].to_s,
				set[1]['border'].to_s,
				set[1]['type'].to_s,
				set[1]['booster'].to_s
			] )[0]
		
		createdSets += 1
		
		
		# Create each card in the set		
		set[1]['cards'].each do |card|
			InsertCard(db, setId, card)
		
			createdCards += 1
		end
		
		
		puts set[1]['name'].to_s + " - Cards: " + set[1]['cards'].length.to_s	
	end
end

############
# Finished #
############

puts "\nSets created: " + createdSets.to_s
puts "Cards created: " + createdCards.to_s
puts "\n\nFinished."