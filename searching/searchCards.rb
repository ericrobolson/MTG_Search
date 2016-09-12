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

# Generate the SQL for card CMC
#	only take ints
#	def initialize(minCmc, maxCmc):
#		minCmc: the minimum cmc that is acceptible
#		maxCmc: the maximum cmc that is acceptible
#	@sql / sql: the generated SQL statement
#	@parameterValues / parameterValues: the list of variables to use as parameters
class GenerateCmcSql
	@sql
	@parameterValues
	
	def initialize(minCmc, maxCmc)
		sqlBuilder = ""
		parameterValuesBuilder = []
		
		# create minimum cmc
		if (minCmc == nil || minCmc <= 0)
			sqlBuilder += "(1 = 1) "
		else
			sqlBuilder += "(card.cmc >= ?)"
			parameterValuesBuilder.push(minCmc)
		end
		
		# create the max cmc
		if (maxCmc == nil || maxCmc <= 0)
			sqlBuilder += "AND (1 = 1)"
		else
			sqlBuilder += "AND (card.cmc <= ?)"
			parameterValuesBuilder.push(maxCmc)
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
	textSearchValues = ["deal", "damage", "target", "player"]
	nameSearchValues = []
	
	minCmc = nil					# should only accept ints or nil
	maxCmc = nil					# should only accept ints or nil
	                                                          
	supertypeIdSearchValues = []	# should only accept ints or nil
	subtypeIdSearchValues = []		# should only accept ints or nil
	typeIdSearchValues = [2]		# should only accept ints or nil
	                                                          
	excludedColorIds = [1,3,5]		# should only accept ints or nil
		
	# Generate the SQL to use in the query
	textSql = GenerateTokenSearchSql.new(textSearchValues, "card.Text", "AND")
	nameSql = GenerateTokenSearchSql.new(nameSearchValues, "card.Name", "AND")	
	
	supertypeIdSql = GenerateTokenSearchSql.new(supertypeIdSearchValues, "cardsupertype.SupertypeId", "OR")
	subtypeIdSql = GenerateTokenSearchSql.new(subtypeIdSearchValues, "cardsubtype.SubtypeId", "OR")
	typeIdSql = GenerateTokenSearchSql.new(typeIdSearchValues, "cardtype.TypeId", "OR")
		
	cmcSql = GenerateCmcSql.new(minCmc, maxCmc)
		
	excludedColorSql = GenerateColorSql.new(excludedColorIds)
	
	# Build the list of query parameters
	parameterValues = []
	
	parameterValues.push(textSql.parameterValues)
	parameterValues.push(nameSql.parameterValues)
	
	parameterValues.push(supertypeIdSql.parameterValues)
	parameterValues.push(subtypeIdSql.parameterValues)
	parameterValues.push(typeIdSql.parameterValues)
	
	parameterValues.push(cmcSql.parameterValues)
	
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
			" + cmcSql.sql + "

			
			-- card power
--			((card.power >= ? OR (? = 0 AND card.power is null)) AND card.power <= ?) AND
			
--			-- card toughness
--			((card.toughness >= ? OR (? = 0 AND card.toughness is null)) AND card.toughness <= ?)
			
			
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