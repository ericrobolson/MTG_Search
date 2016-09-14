# Eric Olson (c) 2016
# v1
# Search for cards that fit the search criteria

require 'sqlite3'
DATABASE_LOCATION = '../databases/'
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'

############################################
# Dynamic SQL statement generation classes #
############################################

# Generate SQL for an array of values which will allow tokenized searching
#	def initialize(searchValues, columnToSearch, operator):
#		searchValues: the array of items to search for
#		columnToSearch: the column to search in the SQL statement
#		operator: e.g. AND, OR; whether to search for all of the items in the list or only one
#	@sql / sql: the generated SQL statement
#	@parameterValues / parameterValues: the list of variables to use as parameters
class GenerateTokenSearchSql
	@sql
	@parameterValues
	
	def initialize(searchValues, columnToSearch, operator)
		sqlBuilder = ""
		parameterValuesBuilder = []
	
		if (searchValues == nil || searchValues.length == 0 || columnToSearch == nil || columnToSearch.length == 0)
			sqlBuilder = "(1 = 1)"
		else
			sqlBuilder += "("
		
			searchValues.each do |searchValue|
				sqlBuilder += "(" + columnToSearch + " like ?) " + operator
				parameterValuesBuilder.push("%" + searchValue.to_s + "%")
			end
			
			sqlBuilder = sqlBuilder.chomp(operator)
			sqlBuilder += ")"
		end
		
		@sql = sqlBuilder
		@parameterValues = parameterValuesBuilder
	end
		
	def sql 
		return @sql
	end
	
	def parameterValues
		return @parameterValues
	end
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
		return @sql
	end
	
	def parameterValues
		return @parameterValues
	end
end

# Generate the SQL for a min number and a max number
#	only take ints
#	def initialize(minNumber, maxNumber):
#		minNumber: the minimum value that is acceptible
#		maxNumber: the maximum value that is acceptible
#		columnToSearch: the column to search in the SQL statement
#	@sql / sql: the generated SQL statement
#	@parameterValues / parameterValues: the list of variables to use as parameters
class GenerateNumberRangeSql
	@sql
	@parameterValues
	
	def initialize(minNumber, maxNumber, columnToSearch)
		sqlBuilder = ""
		parameterValuesBuilder = []
		
		# create minimum
		if (minNumber == nil || minNumber <= 0)
			sqlBuilder += "(1 = 1) "
		else
			sqlBuilder += "(" + columnToSearch + " >= ?)"
			parameterValuesBuilder.push(minNumber)
		end
		
		# create the max
		if (maxNumber == nil || maxNumber <= 0)
			sqlBuilder += "AND (1 = 1)"
		else
			sqlBuilder += "AND (" + columnToSearch + " <= ?)"
			parameterValuesBuilder.push(maxNumber)
		end
		
		@sql = sqlBuilder
		@parameterValues = parameterValuesBuilder
	end
	
	def sql
		return @sql
	end
	
	def parameterValues
		return @parameterValues
	end	
end

# TODO
## Generate the code which determines how many unique colors are acceptible
##	only accepts ints
#class GenerateNumberOfColorsSql
#	@sql
#	@parameterValues
#		
#	def initialize(min, max)
#		sqlBuilder = ""
#		parameterValuesBuilder = []
#	
#		# build the minimum colors required
#		if (min == nil || min == 0)
#			sqlBuilder += " (1 = 1) "
#		else
#			sqlBuilder += "(COUNT(color.ColorId) >= ?)"
#			parameterValuesBuilder.push(min)
#		end
#
#		# build the maximum colors required
#		if (max == nil || max == 0)
#			sqlBuilder += " AND (1 = 1) "
#		else
#			sqlBuilder += " AND (COUNT(color.ColorId) >= ?) "
#			parameterValuesBuilder.push(max)
#		end
#		
#		@sql = sqlBuilder
#		@parameterValues = parameterValuesBuilder
#	end
#	
#	def sql
#		return @sql
#	end
#	
#	def parameterValues
#		return @parameterValues
#	end
#end
#

###############################
# Build and execute the query #
###############################
SQLite3::Database.open(cardInformationDb) do |db|
	# Set the search values 
	textSearchValues = []
	nameSearchValues = []
	
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
		
	# Generate the SQL to use in the query
	textSql = GenerateTokenSearchSql.new(textSearchValues, "card.Text", "AND")
	nameSql = GenerateTokenSearchSql.new(nameSearchValues, "card.Name", "AND")	
	supertypeIdSql = GenerateTokenSearchSql.new(supertypeIdSearchValues, "cardsupertype.SupertypeId", "OR")
	subtypeIdSql = GenerateTokenSearchSql.new(subtypeIdSearchValues, "cardsubtype.SubtypeId", "OR")
	typeIdSql = GenerateTokenSearchSql.new(typeIdSearchValues, "cardtype.TypeId", "OR")
	cmcSql = GenerateNumberRangeSql.new(minCmc, maxCmc, "card.CMC")
	raritySql = GenerateTokenSearchSql.new(rarityIdSearchValues, "card.RarityId", "OR")	
	artistSql = GenerateTokenSearchSql.new(artistIdSearchValues, "card.ArtistId", "OR")
	
	powerSql = GenerateNumberRangeSql.new(minPower, maxPower, "card.Power")
	toughnessSql = GenerateNumberRangeSql.new(minToughness, maxToughness, "card.Toughness")
	
	excludedColorSql = GenerateColorSql.new(excludedColorIds)
	
	# Build the list of query parameters
	parameterValues = []
	
	parameterValues.push(textSql.parameterValues)
	parameterValues.push(nameSql.parameterValues)
	parameterValues.push(supertypeIdSql.parameterValues)
	parameterValues.push(subtypeIdSql.parameterValues)
	parameterValues.push(typeIdSql.parameterValues)
	parameterValues.push(cmcSql.parameterValues)
	parameterValues.push(raritySql.parameterValues)
	parameterValues.push(artistSql.parameterValues)
	parameterValues.push(powerSql.parameterValues)
	parameterValues.push(toughnessSql.parameterValues)
	
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
			" + textSql.sql + " AND

			-- search card name
			" + nameSql.sql + " AND
			
			-- search card supertype
			" + supertypeIdSql.sql + " AND
			
			-- search card subtype
			" + subtypeIdSql.sql + " AND
			
			-- search card type
			" + typeIdSql.sql + " AND
						
			-- Max and Min cmc
			" + cmcSql.sql + " AND
			
			-- card rarity
			" + raritySql.sql + " AND
			
			-- card artist
			" + artistSql.sql + " AND
			
			-- card power
			" + powerSql.sql + " AND
			
			-- card toughness
			" + toughnessSql.sql + "
			
			
		GROUP BY 
			card.CardId
	
		-- Exclude colors the user does not want
		EXCEPT 
			SELECT 
				DISTINCT Name 
			FROM 
				Card card LEFT JOIN CardColor cardcolor
			ON card.cardId = cardcolor.CardId LEFT JOIN 
				Color color 
			ON color.ColorId = cardcolor.ColorId
			
			WHERE
			" + excludedColorSql.sql + ""
		
	# Execute the query	
	result = db.execute(query, parameterValues)

	# Return the query
	puts result
end