# Eric Olson (c) 2016
# Parse the JSON file containing infomation about 
# the Magic The Gathering cards into databases

require 'JSON'
require 'sqlite3'
DATABASE_LOCATION = ''

#####################
# Create the Tables #
#####################
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'
SQLite3::Database.new(cardInformationDb) do |db|
	# Create the table containing sets
	db.execute("CREATE TABLE IF NOT EXISTS CardSet(
		SetId INTEGER PRIMARY KEY ASC,
		Name TEXT NOT NULL,
		Code TEXT NOT NULL,
		ReleaseDate TEXT NOT NULL,
		Border TEXT NOT NULL,
		Type TEXT NOT NULL,
		Booster TEXT NOT NULL,
		CONSTRAINT Unique_Set
		UNIQUE (Name, Code, ReleaseDate, Border, Type, Booster)
	);
	")

	# Create the table containing cards
	db.execute("CREATE TABLE IF NOT EXISTS Card(
		CardId INTEGER PRIMARY KEY ASC,
		Name TEXT NOT NULL,
		Text TEXT,
		CMC INTEGER,
		Power INTEGER,
		Toughness INTEGER,
		SetId INTEGER,
		Number TEXT, -- this is text as there can be letters in teh card number
		Id TEXT,
		ArtistId INTEGER,
		RarityId INTEGER,
		LayoutId INTEGER,
		
		
		CONSTRAINT Unique_Card
		UNIQUE (
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
	);
	")

	# Create card layout table
	db.execute("CREATE TABLE IF NOT EXISTS Layout(
		LayoutId INTEGER PRIMARY KEY ASC,
		Layout TEXT NOT NULL,
		CONSTRAINT Unique_Layout
		UNIQUE(Layout)
	);")

	# Create card rarity table
	db.execute("CREATE TABLE IF NOT EXISTS Rarity(
		RarityId INTEGER PRIMARY KEY ASC,
		Rarity TEXT NOT NULL,
		CONSTRAINT Unique_Rarity
		UNIQUE(Rarity)
	);")

	# Create card artist table
	db.execute("CREATE TABLE IF NOT EXISTS Artist(
		ArtistId INTEGER PRIMARY KEY ASC,
		Artist TEXT NOT NULL,
		CONSTRAINT Unique_Artist
		UNIQUE(Artist)
	);")
		
# Create supertype tables	
	# Create card supertype table
	db.execute("CREATE TABLE IF NOT EXISTS Supertype(
		SupertypeId INTEGER PRIMARY KEY ASC,
		Supertype TEXT NOT NULL,
		CONSTRAINT Unique_Supertype
		UNIQUE(Supertype)
	);")

	# Create the supertype linking table
	db.execute("CREATE TABLE IF NOT EXISTS CardSupertype (
		CardSupertypeId INTEGER PRIMARY KEY ASC,
		SupertypeId INTEGER NOT NULL,
		CardId INTEGER NOT NULL,
		CONSTRAINT Unique_CardSupertype
		UNIQUE (SupertypeId, CardId)	
	);")

	
# Create type tables	
	# Create card type table
	db.execute("CREATE TABLE IF NOT EXISTS Type(
		TypeId INTEGER PRIMARY KEY ASC,
		Type TEXT NOT NULL,
		CONSTRAINT Unique_Type
		UNIQUE(Type)
	);")

	# Create the type linking table
	db.execute("CREATE TABLE IF NOT EXISTS CardType (
		CardTypeId INTEGER PRIMARY KEY ASC,
		TypeId INTEGER NOT NULL,
		CardId INTEGER NOT NULL,
		CONSTRAINT Unique_CardType
		UNIQUE (TypeId, CardId)	
	);")

# Create subtype tables	
	# Create card subtype table
	db.execute("CREATE TABLE IF NOT EXISTS Subtype(
		SubtypeId INTEGER PRIMARY KEY ASC,
		Subtype TEXT NOT NULL,
		CONSTRAINT Unique_Subtype
		UNIQUE(Subtype)
	);")
		
	# Create the subtype linking table
	db.execute("CREATE TABLE IF NOT EXISTS CardSubtype (
		CardSubtypeId INTEGER PRIMARY KEY ASC,
		SubtypeId INTEGER NOT NULL,
		CardId INTEGER NOT NULL,
		CONSTRAINT Unique_CardSubtype
		UNIQUE (SubtypeId, CardId)	
	);")
	
# Create color tables	
	# Create color table
	db.execute("CREATE TABLE IF NOT EXISTS Color(
		ColorId INTEGER PRIMARY KEY ASC,
		Color TEXT NOT NULL,
		Symbol TEXT NOT NULL,
		CONSTRAINT Unique_Color
		UNIQUE(Color, Symbol))
	;")
	
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('Green', 'G');")
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('Blue', 'U');")
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('Black', 'B');")
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('Red', 'R');")
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('White', 'W');")
	db.execute("INSERT INTO Color (Color, Symbol) VALUES ('Colorless', 'C');")

	# Create color linking table
	db.execute("CREATE TABLE IF NOT EXISTS CardColor (
		CardColorId INTEGER PRIMARY KEY ASC,
		ColorId INTEGER NOT NULL,
		CardId INTEGER NOT NULL,
		CONSTRAINT Unique_CardColor
		UNIQUE (ColorId, CardId)
	);")
end

############
# Finished #
############

puts "\n\nFinished."