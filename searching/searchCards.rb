# Eric Olson (c) 2016
# v1
# Search for cards that fit the search criteria

require 'sqlite3'
DATABASE_LOCATION = '../databases/'
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'

# TODO: Change the rest of the SQL generation classes to use functions, so that there are less dependencies used

####################################
# Dynamic SQL statement generation #
####################################

# Generate SQL for an array of values which will allow tokenized searching
#	(searchValues, columnToSearch, operator, parameterValues):
#		searchValues: the array of items to search for
#		columnToSearch: the column to search in the SQL statement
#		operator: e.g. AND, OR; whether to search for all of the items in the list or only one
#		parameterValues: the array containing values to be used in the  SQL statement
def TokenSearchSql(searchValues, columnToSearch, operator, parameterValues)
	sqlBuilder = ""
	
	if (searchValues == nil || searchValues.length == 0 || columnToSearch == nil || columnToSearch.length == 0)
		sqlBuilder = "(1 = 1)"
	else
		sqlBuilder += "("
	
		searchValues.each do |searchValue|
			sqlBuilder += "(" + columnToSearch + " like ?) " + operator
			parameterValues.push("%" + searchValue.to_s + "%")
		end
		
		sqlBuilder = sqlBuilder.chomp(operator)
		sqlBuilder += ")"
	end
	
	return sqlBuilder
end

# Generate the SQL for which colors to exclude
#	only takes ints
#	def initialize(searchValues):
#		searchValues: the array of items to search for
#	@sql / sql: the generated SQL statement
#	@parameterValues / parameterValues: the list of variables to use as parameters
class GenerateColorSql
	@sql
	@parameterValues
	
	def initialize(searchValues)
		sqlBuilder = ""
		parameterValuesBuilder = []
	
		if (searchValues == nil || searchValues.length == 0)
			sqlBuilder = "(0 = 1)"
		else
			sqlBuilder = "color.ColorId IN ("
			searchValues.each do |searchValue|
				sqlBuilder += "?,"
				parameterValuesBuilder.push(searchValue)
			end
			# need to remove the last char, as it's a ',' when there's no more items
			sqlBuilder = sqlBuilder.chop + ")"			
		end
		
		@sql = sqlBuilder
		@parameterValues = parameterValuesBuilder
	end
	
	def sql
		exceptClause = "
		EXCEPT 
			SELECT 
				DISTINCT Name 
			FROM 
				Card card LEFT JOIN CardColor cardcolor
			ON card.cardId = cardcolor.CardId LEFT JOIN 
				Color color 
			ON color.ColorId = cardcolor.ColorId
			
			WHERE
		"
	
		return exceptClause + @sql
	end
	
	def parameterValues
		return @parameterValues
	end
end

# Generate the SQL for a min number and a max number
#	minNumber: the minimum int value that is acceptible
#	maxNumber: the maximum int value that is acceptible
#	columnToSearch: the column to search in the SQL statement
#	parameterValues / parameterValues: the list of variables to use as parameters
def NumberRangeSql(minNumber, maxNumber, columnToSearch, parameterValues)
	sqlBuilder = ""
	
	# create minimum
	if (minNumber == nil || minNumber <= 0)
		sqlBuilder += "(1 = 1) "
	else
		sqlBuilder += "(" + columnToSearch + " >= ?)"
		parameterValues.push(minNumber)
	end
	
	# create the max
	if (maxNumber == nil || maxNumber <= 0)
		sqlBuilder += "AND (1 = 1)"
	else
		sqlBuilder += "AND (" + columnToSearch + " <= ?)"
		parameterValues.push(maxNumber)
	end
	
	return sqlBuilder
end


# Whether to exclude monocolor, exclude multicolor, or include both
module ExcludeMultiOrMono
	MONOCOLOR = 1
	MULTICOLOR = 2
	NEITHER = 3
end

# Generate the SQL for excluding monocolor, excluding multicolor, or including both
#	must take either ExcludeMultiOrMono:: values
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


###############################
# Build and execute the query #
###############################
SQLite3::Database.open(cardInformationDb) do |db|
	# Set the search values 
	textSearchValues = []			# can accept any sort of text values
	nameSearchValues = []			# can accept any sort of text values
	
	minCmc = nil					# should only accept ints or nil
	maxCmc = nil					# should only accept ints or nil
	
	minPower = nil					# should only accept ints or nil
	maxPower = nil					# should only accept ints or nil
		
	minToughness = nil				# should only accept ints or nil
	maxToughness = nil				# should only accept ints or nil
	
	
	supertypeIdSearchValues = []	# should only accept ints or nil
	subtypeIdSearchValues = []		# should only accept ints or nil
	typeIdSearchValues = []			# should only accept ints or nil
	rarityIdSearchValues = []		# should only accept ints or nil
	artistIdSearchValues = []		# should only accept ints or nil
	                                                          
	excludedColorIds = []			# should only accept ints or nil
	
	excludeMultiOrMono = ExcludeMultiOrMono::NEITHER	# can only be part of th ExcludeMultiOrMono enum
	
	# Generate the SQL to use in the query

#	TokenSearchSql(typeIdSearchValues, "cardtype.TypeId", "OR", parameterValues)

	
	
	
	
	
	
	excludedColorSql = GenerateColorSql.new(excludedColorIds)
	
	
	ExcludeMultiOrMonoSql = GenerateMultiOrMonoSql.new(excludeMultiOrMono)
	
	
	# Build the list of query parameters
	parameterValues = []
	
	parameterValues.push(excludedColorSql.parameterValues)
	
	# Build the query
	query = "	
		SELECT
			DISTINCT Name 
		FROM 
			Card card LEFT JOIN 
				CardColor color 
			ON color.CardId = card.CardId LEFT JOIN
				CardSupertype cardsupertype 
			ON cardsupertype.CardId = card.CardId LEFT JOIN
				CardSubtype cardsubtype				
			ON cardsubtype.CardId = card.CardId LEFT JOIN
				CardType cardtype
			ON cardtype.CardId = card.CardId 
		WHERE
			-- search text 
			" + TokenSearchSql(textSearchValues, "card.Text", "AND", parameterValues) + " AND

			-- search card name
			" + TokenSearchSql(nameSearchValues, "card.Name", "AND", parameterValues) + " AND
			
			-- search card supertype
			" + TokenSearchSql(supertypeIdSearchValues, "cardsupertype.SupertypeId", "OR", parameterValues) + " AND
			
			-- search card subtype
			" + TokenSearchSql(subtypeIdSearchValues, "cardsubtype.SubtypeId", "OR", parameterValues) + " AND
			
			-- search card type
			" + TokenSearchSql(typeIdSearchValues, "cardtype.TypeId", "OR", parameterValues) + " AND
						
			-- Max and Min cmc
			" + NumberRangeSql(minCmc, maxCmc, "card.CMC", parameterValues) + " AND
			
			-- card rarity
			" + TokenSearchSql(rarityIdSearchValues, "card.RarityId", "OR", parameterValues) + " AND
			
			-- card artist
			" + TokenSearchSql(artistIdSearchValues, "card.ArtistId", "OR", parameterValues) + " AND
			
			-- card power
			" + NumberRangeSql(minPower, maxPower, "card.Power", parameterValues) + " AND
			
			-- card toughness
			" + NumberRangeSql(minToughness, maxToughness, "card.Toughness", parameterValues) + "			
			
		GROUP BY 
			card.CardId
	
		-- Exclude colors the user does not want
		" + excludedColorSql.sql + "
			
		-- Exclude mono color cards, or multi color cards
		" + ExcludeMultiOrMonoSql.sql + "
			"
			
		
		
	# Execute the query	
	result = db.execute(query, parameterValues)

	# Return the query
	puts result
end