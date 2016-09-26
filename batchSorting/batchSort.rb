# Eric Olson (c) 2016
# v1
# Search for cards that fit the search criteria

require 'sqlite3'


# Whether to exclude monocolor, exclude multicolor, or include both
module ExcludeMultiOrMono
	MONOCOLOR = 1
	MULTICOLOR = 2
	NEITHER = 3
end

# Generate the SQL for excluding monocolor, excluding multicolor, or including both
#	must take either ExcludeMultiOrMono::values
#	def initialize(filter):
#		filter: sets whether to exclude multicolor, exclude monocolor, or include both
#	@sql / sql: the generated SQL statement
class GenerateMultiOrMonoSql
	def excludeMultiColorSql 
		return "
		EXCEPT
		SELECT
			DISTINCT Card.Name
		FROM 
			Card card LEFT JOIN 
				CardColor color 
			ON color.CardId = card.CardId
		
		GROUP BY Card.CardId
		HAVING Count(Color.ColorId) > 1"
	end

	def excludeMonoColorSql 
		return "
		EXCEPT
		SELECT
			DISTINCT Card.Name
		FROM 
			Card card LEFT JOIN 
				CardColor color 
			ON color.CardId = card.CardId
		
		GROUP BY Card.CardId
		HAVING Count(Color.ColorId) = 1"
	end
	
	def includeBoth 
		return 	"-- exclude nothing"	
	end
		
		
	@filter
		
	def initialize(filter)	
		@filter = filter
	end
	
	def sql 	
		if (@filter == ExcludeMultiOrMono::MULTICOLOR)
			return excludeMultiColorSql
		elsif (@filter == ExcludeMultiOrMono::MONOCOLOR)
			return excludeMonoColorSql
		else
			return includeBoth		
		end
	end	
end

# Generate a JSON object containing cards sorted by mana cost
#	def SortByColor(cardsToSort)
#		cardsToSort: a list of card names to sort 
def SortByCmc(cardsToSort)
	database_location = '../databases/'
	cardInformationDb = database_location + 'CardInformation.db'
		
	cardsByCmc = []
	
	SQLite3::Database.open(cardInformationDb) do |db|				
		# Insert all the batch files into a temporary table to allow faster sorting
		db.execute("CREATE TEMPORARY TABLE BatchCards (Name TEXT)")
		cardsToSort.each do |card|
			db.execute("INSERT INTO BatchCards (Name) VALUES (?)", card)
		end
		
		# Sort all cards that are 0 cmc or nil cmc
		cards = db.execute("
			SELECT 
				DISTINCT Card.Name
			FROM
				Card INNER JOIN
					BatchCards
				ON BatchCards.Name = Card.Name
			WHERE
				Card.CMC < 1 OR Card.CMC IS NULL
		")
			
		if (cards.length > 0)
			jsonObj = {"cmc" => "0", "cards" => cards}
			cardsByCmc.push(jsonObj)
		end			
				
		# Sort all cards by cmc
		cmcRange = [1,2,3,4,5,6,7,8,9]
		cmcRange.each do |cmc|
			cards = db.execute("
				SELECT 
					DISTINCT Card.Name
				FROM
					Card INNER JOIN
						BatchCards
					ON BatchCards.Name = Card.Name
				WHERE
					Card.CMC = ?
			", cmc)
				
			if (cards.length > 0)
				jsonObj = {"cmc" => cmc.to_s, "cards" => cards}
				cardsByCmc.push(jsonObj)
			end			
		end
		
		# Sort cards with cmc greater than 10
		cards = db.execute("
			SELECT 
				DISTINCT Card.Name
			FROM
				Card INNER JOIN
					BatchCards
				ON BatchCards.Name = Card.Name
			WHERE
				Card.CMC >= 10
		")
			
		if (cards.length > 0)
			jsonObj = {"cmc" => "10+", "cards" => cards}
			cardsByCmc.push(jsonObj)
		end			
		
		
		# Delete the temp table
		db.execute("DROP TABLE BatchCards")	
	end
		
	return cardsByCmc
end

# Generate a JSON object containing cards sorted by color
#	def SortByColor(cardsToSort)
#		cardsToSort: a list of card names to sort 
def SortByColor(cardsToSort)
	database_location = '../databases/'
	cardInformationDb = database_location + 'CardInformation.db'

	excludeMonoColor = GenerateMultiOrMonoSql.new(ExcludeMultiOrMono::MONOCOLOR)
	excludeMultiColor = GenerateMultiOrMonoSql.new(ExcludeMultiOrMono::MULTICOLOR)

	# The array that contains JSON objects of all the cards by colors
	cardsByColor = []
	
	
	SQLite3::Database.open(cardInformationDb) do |db|
		# Get all colors and names
		colorList = db.execute("SELECT Color, ColorId from Color")
				
		# Insert all the batch files into a temporary table to allow faster sorting
		db.execute("CREATE TEMPORARY TABLE BatchCards (Name TEXT)")
		cardsToSort.each do |card|
			db.execute("INSERT INTO BatchCards (Name) VALUES (?)", card)
		end
		
		# Sort all multicolor cards that are in the batch list
		multicolorCards = db.execute("	
			SELECT 
				DISTINCT Card.Name
			FROM
				Card INNER JOIN
					BatchCards
				ON Card.Name = BatchCards.Name
			" + excludeMonoColor.sql + "
		")
				
		if (multicolorCards.length > 0)
			jsonObj = {"color" => "Multicolor", "cards" => multicolorCards}
			cardsByColor.push(jsonObj)
		end
			
		# Sort all monocolor cards in the batch list
		colorList.each do |color, colorId|
			cards = db.execute("
				SELECT 
					DISTINCT Card.Name
				FROM
					Card INNER JOIN
						CardColor
					ON Card.CardId = CardColor.CardId INNER JOIN
						BatchCards
					ON BatchCards.Name = Card.Name
				WHERE
					CardColor.ColorId = ?
				
				-- exclude multicolor cards
				" + excludeMultiColor.sql + "
			", colorId)
				
			if (cards.length > 0)
				jsonObj = {"color" => color, "cards" => cards}
				cardsByColor.push(jsonObj)
			end
			
			
		end
		
		# Delete the temp table
		db.execute("DROP TABLE BatchCards")
	end
	
	return cardsByColor
end

# Print the json object of colors / cards
#	jsonObj: the json object to print, as generated by SortByColor
def SplitJsonObj(jsonObj, sortedBy)
	jsonObj.each do |color|
		puts "\n---" + color[sortedBy] + "---\n"
		puts color["cards"]
	end
end

# Generate an array from a file where each line is an item
#	fileName: the string name of the file
def GenerateListFromFile(fileName)
	f = File.open(fileName, "r")
	items = []
	
	f.each_line do |item|
		items.push(item.strip)
	end
	
	return items
end

################
# Main Program #
################

cards = GenerateListFromFile("batch_sort.txt")

jsonObj = SortByCmc cards
#jsonObj = SortByColor cards


SplitJsonObj(jsonObj, "cmc")