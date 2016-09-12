# Eric Olson (c) 2016
# v1
# Search for cards that fit the search criteria

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

SQLite3::Database.open(cardInformationDb) do |db|
	puts db.execute("	
		SELECT
			DISTINCT Name 
		FROM 
			Card card LEFT JOIN 
				CardColor color 
			ON color.cardid = card.cardid LEFT JOIN
				CardSupertype cardsupertype 
			ON cardsupertype.cardId = card.cardId LEFT JOIN
				Supertype supertype 
			ON supertype.SupertypeId = cardsupertype.supertypeid LEFT JOIN
				CardType cardtype
			ON cardtype.cardId = card.cardId LEFT JOIN
				Type type
			ON cardtype.typeId = type.typeId
		WHERE
			-- Max and Min cmc; if minCmc is = 0, include null results
			card.CMC <= ? AND (card.cmc >= ? OR card.cmc is null AND ? <=0) AND
			
			-- search card text
			(0 = ? OR card.Text like ?) AND
			
			-- search card name
			(0 = ? OR card.Name like ?) AND
			
			-- search card supertype 
			(0 = ? OR supertype = ?) AND
			-- search card type
			(0 = ? OR type = ?) AND
			
			-- card power
			((card.power >= ? OR (? = 0 AND card.power is null)) AND card.power <= ?) AND
			
			-- card toughness
			((card.toughness >= ? OR (? = 0 AND card.toughness is null)) AND card.toughness <= ?)
						
		GROUP BY 
			card.CardId
		HAVING
			-- get multicolored less than or equal to the number of colors, monocolored, or both
			(1 = ? AND COUNT(color.colorid) > 1 AND COUNT(color.colorid) <= ?) OR (1 = ? AND COUNT(color.colorid) <= 1) OR (? = ?) 

	
		-- whether to exclude certain colors or not
		EXCEPT 
			SELECT 
				DISTINCT Name 
			FROM 
				Card card LEFT JOIN CardColor cardcolor
			ON card.cardId = cardcolor.CardId LEFT JOIN 
				Color color 
			ON color.ColorId = cardcolor.ColorId
			
			WHERE
				(0 = ? AND color.Symbol = 'R') OR		-- includeRed
				(0 = ? AND color.Symbol = 'U') OR 		-- includeBlue
				(0 = ? AND color.Symbol = 'G') OR 		-- includeGreen
				(0 = ? AND color.Symbol = 'W') OR 		-- includeWhite
				(0 = ? AND color.Symbol = 'B') OR 		-- includeBlack
				(0 = ? AND color.colorId is null) 		-- includeColorless
	
		", [
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
end