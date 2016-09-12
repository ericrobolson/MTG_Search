# Eric Olson (c) 2016
# v1
# Search for cards that fit the search criteria

##########################3
# TODO
#	Change SQL to generate it based off of lists; e.g. use foreach loops for text search strings like 
#

# sql = ""
# parametervalues = []
# foreach text in search_text_list
# 	sql += "text like ?"
# 	parametervalues.push(text)
# 	return sql, parametervalues
# 	then, insert the sql, and add the parametervalues to the query


require 'sqlite3'
DATABASE_LOCATION = '../databases/'
cardInformationDb = DATABASE_LOCATION + 'CardInformation.db'

includeRed = 1
includeBlue = 1
includeGreen = 1
includeWhite = 1
includeBlack = 1
includeColorless = 1

onlyMulticolor = 1
onlyMonocolor = 1
maxColors = 3

searchText = 1
cardText = "land"
cardText = '%' + cardText + '%'

searchName = 1
cardName = ""
cardName = '%' + cardName + '%'

searchSupertype = 1
supertype = "Legendary"

searchType = 1
type = "Creature"

maxCmc = 10000
minCmc = 0

minPower = 0
maxPower = 20
minToughness = 0
maxToughness = 10000

# class that contains generated SQL as well as the parametervalues for it
#	sql: the generated SQL statement
#	conditions: an array of variables to use as conditions
class GeneratedWhereAndCondition
	@sql
	@parameterValues
	
	def initialize(searchValues, objToSearch)
		sql = ""
		parameterValues = []
	
		# if there's nothing to search for, then the generated SQL is a simple always true statement 
		if (searchValues == nil || searchValues.length == 0 ||
			objToSearch == nil || objToSearch.length == 0)
			
			sql = "(1 = 1) AND"
		else
			searchValues.each do |searchValue|
				sql += "(" + objToSearch + " like ?) AND "
				parameterValues.push("%" + searchValue.to_s + "%")
			end
		end
		
		@sql = sql
		@parameterValues = parameterValues
	end
		
	def sql 
		return @sql
	end
	
	def parameterValues
		return @parameterValues
	end
end
#
## Generate SQL statements based on an array of text to search
#def GenerateCardTextSql(searchArray, objToSearch)
#	sql = ""
#	conditions = []
#	
#	# if there's nothing to search for, then the generated SQL is a simple always true statement 
#	if (searchArray == nil || searchArray.length == 0 || objToSearch == nil || objToSearch.length == 0)
#		sql = "1 = 1 AND"
#	else
#		searchArray.each do |searchObj|
#			sql += "(" + objToSearch + " like ?) AND "
#			conditions.push("%" + searchObj.to_s + "%")
#		end
#	end
#		
#	return [sql, conditions]
#end
#

SQLite3::Database.open(cardInformationDb) do |db|
	textSearchValues = ["enters the battlefield"]
	nameSearchValues = []
	
	supertypeIdSearchValues = []
	subtypeIdSearchValues = []
	typeIdSearchValues = []
	
	# build the SQL and conditions
	textSql = GeneratedWhereAndCondition.new(textSearchValues, "card.Text")
	nameSql = GeneratedWhereAndCondition.new(nameSearchValues, "card.Name")	
	
	supertypeIdSql = GeneratedWhereAndCondition.new(supertypeIdSearchValues, "cardsupertype.SupertypeId")
	subtypeIdSql = GeneratedWhereAndCondition.new(subtypeIdSearchValues, "cardsubtype.SubtypeId")
	typeIdSql = GeneratedWhereAndCondition.new(typeIdSearchValues, "cardtype.TypeId")
	
	# build the list of parameterValues
	parameterValues = []
	
	parameterValues.push(textSql.parameterValues)
	parameterValues.push(nameSql.parameterValues)
	parameterValues.push(supertypeIdSql.parameterValues)
	parameterValues.push(subtypeIdSql.parameterValues)
	parameterValues.push(typeIdSql.parameterValues)
	
	# build the query
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
			" + textSql.sql + "

			-- search card name
			" + nameSql.sql + "
			
			-- search card supertype
			" + supertypeIdSql.sql + "
			
			-- search card subtype
			" + subtypeIdSql.sql + "
			
			-- search card type
			" + typeIdSql.sql + "

			-- the last statement has an 'and'
			1=1
			
			
--			-- Max and Min cmc; if minCmc is = 0, include null results
--			card.CMC <= ? AND (card.cmc >= ? OR card.cmc is null AND ? <=0) AND
			
--			-- card power
--			((card.power >= ? OR (? = 0 AND card.power is null)) AND card.power <= ?) AND
			
--			-- card toughness
--			((card.toughness >= ? OR (? = 0 AND card.toughness is null)) AND card.toughness <= ?)
		
			
			
		GROUP BY 
			card.CardId
--		HAVING
--			-- get multicolored less than or equal to the number of colors, monocolored, or both
--			(1 = ? AND COUNT(color.colorid) > 1 AND COUNT(color.colorid) <= ?) OR (1 = ? AND COUNT(color.colorid) <= 1) OR (? = ?) 
--
	
		-- whether to exclude certain colors or not
--		EXCEPT 
--			SELECT 
--				DISTINCT Name 
--			FROM 
--				Card card LEFT JOIN CardColor cardcolor
--			ON card.cardId = cardcolor.CardId LEFT JOIN 
--				Color color 
--			ON color.ColorId = cardcolor.ColorId
--			
--			WHERE
--				(0 = ? AND color.Symbol = 'R') OR		-- includeRed
--				(0 = ? AND color.Symbol = 'U') OR 		-- includeBlue
--				(0 = ? AND color.Symbol = 'G') OR 		-- includeGreen
--				(0 = ? AND color.Symbol = 'W') OR 		-- includeWhite
--				(0 = ? AND color.Symbol = 'B') OR 		-- includeBlack
--				(0 = ? AND color.colorId is null) 		-- includeColorless
--	
		"
		
		
	result = db.execute(query, parameterValues)

	puts result
	
	
=begin		
		puts db.execute(query,[
			# the max and min cmc
			maxCmc, 
			minCmc,minCmc,
			
			#card text
			searchText,
			cardText,		
			
			# card name
			searchName,
			cardName,
			
			# card supertype
			searchSupertype,
			supertype,
			
			# card type
			searchType,
			type,
			
			# card power
			minPower, minPower, 
			maxPower,
			
			# card toughness
			minToughness, minToughness,
			maxToughness,
			
			# determine multicolored or monocolored
			onlyMulticolor,
			maxColors,
			onlyMonocolor,
			onlyMulticolor,
			onlyMonocolor,
			
			# search colors
			includeRed, 
			includeBlue,
			includeGreen,
			includeWhite,
			includeBlack,
			includeColorless
			]
		)
		
=end
end