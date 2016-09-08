# Eric Olson (c) 2016

# parse the JSON file containing infomation about 
# the Magic The Gathering cards into databases


require 'JSON'
require 'sqlite3'
DATABASE_LOCATION = 'databases/'


########################
# create the databases #
########################
setDb = DATABASE_LOCATION + 'CardSet.db'
SQLite3::Database.new(setDb) do |db|
	db.execute("
		DROP TABLE IF EXISTS CardSet
	")
	
	db.execute("
	CREATE TABLE CardSet(
		SetId INTEGER PRIMARY KEY ASC,
		Name TEXT NOT NULL,
		Code TEXT NOT NULL,
		ReleaseDate TEXT,
		Border TEXT,
		Type TEXT,
		Booster TEXT
	)
	")
end
cardDb = DATABASE_LOCATION + 'Card.db'
SQLite3::Database.new(cardDb) do |db|
	db.execute("
		DROP TABLE IF EXISTS Card
	")
	
	db.execute("
	CREATE TABLE Card(
		CardId INTEGER PRIMARY KEY ASC,
		Name TEXT NOT NULL,
		ColorIdentity TEXT,
		Text TEXT NOT NULL,
		Artist TEXT,
		Id TEXT,
		Layout TEXT,
		Number TEXT,
		OriginalText TEXT,
		OriginalType TEXT,
		Rarity TEXT,
		Type TEXT,
		Types TEXT,
		SetId INTEGER	
	)
	")

end


##########################################
# parse the json file into sets of cards #
##########################################
puts "\n\nStarting..."
puts "\n\n..."

json = File.read('rescources/AllSets-x.json')

createdSets = 0
createdCards = 0

allSets = JSON.parse(json)
allSets.each do |set|
	##################
	# create the set #
	##################
	setId = -1
	
	SQLite3::Database.open(setDb) do |db|
		db.execute("
			INSERT INTO CardSet 
					(Name, Code, ReleaseDate, Border, Type, Booster)
			VALUES 	(?, 	?, 		?, 			?, 		?,		?)",
			[set[1]['name'].to_s, 
				set[1]['code'].to_s,
				set[1]['releaseDate'].to_s,
				set[1]['border'].to_s,
				set[1]['type'].to_s,
				set[1]['booster'].to_s
			])

		setId = (db.execute("select last_insert_rowid();"))
		createdSets += 1
	end

	###############################
	# create each card in the set #
	###############################
	SQLite3::Database.open(cardDb) do |db|
		set[1]['cards'].each do |card|
			db.execute("
				INSERT INTO Card
					(Name, ColorIdentity, Text, Artist, Id, Layout, 
						Number, OriginalText, OriginalType, Rarity, Type, Types, SetId)
					VALUES
					(?,	?, ?, ?, ?,	?, ?, ?, ?, ?, ?, ?, ?)",
				[
					card['name'].to_s,
					card['colorIdentity'].to_s,
					card['text'].to_s,
					card['artist'].to_s,
					card['id'].to_s,
					card['layout'].to_s,
					card['number'].to_s,
					card['originalText'].to_s,
					card['originalType'].to_s,
					card['rarity'].to_s,
					card['type'].to_s,
					card['types'].to_s,
					setId.to_s
				])
							
			createdCards += 1
			#puts "set #: " + createdSets.to_s + "; card #: " + createdCards.to_s + "; name: " + card['name'].to_s
		end
	end
end


############
# Finished #
############
puts "\nSets created: " + createdSets.to_s
puts "Cards created: " + createdCards.to_s
puts "\n\nFinished."