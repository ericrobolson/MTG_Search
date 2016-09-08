require 'rubygems'
require 'json'
require 'pp'
###############################################
################ TO DO: #######################
###############################################

## Rework how color selection works; should be done in PutCardInFile()

## Rework how parameters are passed



def GetBatchCards(fileName)
	f = File.new(fileName)
	batchCards = Hash.new(false)
	f.each_line do |line|
		formattedLine = line.strip!
		if formattedLine == nil
			formattedLine = line
		end
		batchCards[formattedLine] = true
	end
	f.close
	return batchCards
end

# create the files
class CardFiles
	@@resultsPath = "results/"
	
	# file names
	@@redFileName = @@resultsPath + "RedCards.txt"
	@@whiteFileName = @@resultsPath + "WhiteCards.txt"
	@@blueFileName = @@resultsPath + "BlueCards.txt"
	@@greenFileName = @@resultsPath + "GreenCards.txt"
	@@blackFileName = @@resultsPath + "BlackCards.txt"
	@@landFileName = @@resultsPath + "LandCards.txt"
	@@colorlessFileName = @@resultsPath + "ColorlessCards.txt"
	@@multiFileName = @@resultsPath + "MultiColorCards.txt"
	@@unknownFileName = @@resultsPath + "UnknownCards.txt"
	@@allResultsFileName = @@resultsPath + "AllResults.txt"
	
	# colors to include
	@@includeRed = true
	@@includeWhite = false
	@@includeBlue = false
	@@includeBlack = false
	@@includeGreen = true
	@@includeLand = true
	@@includeColorless = true
	@@includeMultiColor = true
	
	# open the files
	@@redFile = File.new(@@redFileName, "w+")
	@@whiteFile = File.new(@@whiteFileName, "w+")
	@@blueFile = File.new(@@blueFileName, "w+")
	@@greenFile = File.new(@@greenFileName, "w+")
	@@blackFile = File.new(@@blackFileName, "w+")
	@@landFile = File.new(@@landFileName, "w+")
	@@colorlessFile = File.new(@@colorlessFileName, "w+")
	@@multiFile = File.new(@@multiFileName, "w+")
	@@unknownFile = File.new(@@unknownFileName, "w+")
	@@allResultsFile = File.new(@@allResultsFileName, "w+")
	
	
	
	def allResultsFile(f)
		@@allResultsFile.puts f
	end
	
	def redFile(f) 
		@@redFile.puts f
	end
	
	def whiteFile(f)
		@@whiteFile.puts f
	end
	
	def blueFile(f)
		@@blueFile.puts f
	end
	
	def greenFile(f)
		@@greenFile.puts f
	end
	
	def blackFile(f)
		@@blackFile.puts f
	end
	
	def landFile(f)
		@@landFile.puts f
	end
	
	def colorlessFile(f)
		@@colorlessFile.puts f
	end
	
	def multiFile(f)
		@@multiFile.puts f
	end
	
	def unknownFile(f)
		@@unknownFile.puts f
	end
	
	def DeleteAndMergeFiles(includeFile, fileName)
		if (includeFile == false)
			File.delete(fileName)
		else
			# put it with all the results we get
			@@allResultsFile.puts File.read(fileName)
		end
	end
	
	def CloseFiles
		# close the files
		@@redFile.close
		@@whiteFile.close
		@@blueFile.close
		@@greenFile.close
		@@blackFile.close
		@@landFile.close
		@@colorlessFile.close
		@@multiFile.close
		@@unknownFile.close
		
		
		# delete the files we don't need
		DeleteAndMergeFiles @@includeRed, @@redFileName
		DeleteAndMergeFiles @@includeWhite, @@whiteFileName
		DeleteAndMergeFiles @@includeBlue, @@blueFileName
		DeleteAndMergeFiles @@includeBlack, @@blackFileName
		DeleteAndMergeFiles @@includeGreen, @@greenFileName
		DeleteAndMergeFiles @@includeColorless, @@colorlessFileName
		DeleteAndMergeFiles @@includeLand, @@landFileName
		DeleteAndMergeFiles @@includeMultiColor, @@multiFileName


		@@allResultsFile.close
	end
end

# Take the current card information and put the card in the correct file
def PutCardInFile(cardColors, cardTypes, cardName, cardFiles, finished)
	# get the colors and types
	colors = cardColors.to_s.tr('[]"', '').split(" ")
	types = cardTypes.to_s.tr('[]"', '').split(" ")
	
	# Put the card in the proper file
	# Lands
	if (types.include? "Land")
		cardFiles.landFile cardName
	# multi color card
	elsif (colors.length > 1)
		cardFiles.multiFile cardName
	# colorless card
	elsif (colors.length == 0)
		cardFiles.colorlessFile cardName
	# red
	elsif (colors.include? "Red")
		cardFiles.redFile cardName
	# white
	elsif (colors.include? "White")
		cardFiles.whiteFile cardName
	# blue
	elsif (colors.include? "Blue")
		cardFiles.blueFile cardName
	# green
	elsif (colors.include? "Green")
		cardFiles.greenFile cardName
	# black
	elsif (colors.include? "Black")
		cardFiles.blackFile cardName				
	# unknown
	else
		cardFiles.unknownFile cardName
	end
	
	finished[cardName] = true
end

# Checks if a card text contains all instances in the array of search strings
def CardContainsAllWords(arrayOfSearchStrings, cardText)
	wordsToMatch = arrayOfSearchStrings.length
	numberOfMatches = 0
	
	text = cardText.downcase
		
	arrayOfSearchStrings.each do |searchString|
		if (cardText.include? searchString.downcase)
			numberOfMatches += 1
		end
	end
		
	return (wordsToMatch == numberOfMatches)
end

################
# Script Begin #
################

#####################################
## Add an option for only outputting single cards, or outputting multiple cards
## Add an option to batch parse a file of card names
##
##
	# load the cards
	# uses mtgjson.com, AllSets + Extras
	json = File.read('rescources/AllSets-x.json')
	allSets = JSON.parse(json)

	fileManager = CardFiles.new
	
	finishedCards = Hash.new(false)
	
	# get the batch cards
	batchCards = GetBatchCards "BatchFile.txt"
		
	# set the criteria for the card
	nameToSearch = ""
	searchStrings = ["have haste"]
	
	# set which criteria to use when searching
	searchName = false
	searchMythicRare = false
	searchRare = false
	searchUncommon = false
	searchCommon = false
	searchBasicLand = false
	searchSpecial = false
	searchText = true
	
	# if using batch file, only parse out the contents in that file	
	useBatchFile = false
	
	# go through each card
	allSets.each do |set|
		set[1]['cards'].each do |card|
			
			# set the values to search on
			name = card['name']
			rarity = card['rarity']
			text = card['text'].to_s.downcase
			
			
			# set the variables we use when determining a match
			isName = false
			isMythicRare = false
			isRare = false
			isUncommon = false
			isCommon = false
			isBasicLand = false
			isSpecial = false
			containsText = false
				
			# check if the thing matches the search criteria
			if (searchName)
				isName = nameToSearch.downcase.Include?(name.downcase)
			end
			
			if (searchMythicRare)
				isMythicRare = rarity == "Mythic Rare"
			end
			
			if (searchRare)
				isRare = rarity == "Rare"
			end
			
			if (searchUncommon)
				isUncommon = rarity == "Uncommon"
			end
			
			if (searchCommon)
				isCommon = rarity == "Common"
			end
			
			if (searchBasicLand)
				isBasicLand = rarity == "Basic Land"
			end
			
			if (searchSpecial)
				isSpecial = rarity == "Special"
			end
			
			if (searchText)
				containsText = CardContainsAllWords searchStrings, text
			end
			
			# if we are using a batch file, parse out its contents
			if useBatchFile and batchCards[name] == true
				batchCards[name] = false
				PutCardInFile card['colors'], card['types'], name, fileManager, finishedCards
			
			# check if it is a card that needs ot be added to a file and hasn't yet			
			elsif (((searchName and isName) || (searchText and containsText) || (searchMythicRare and isMythicRare) || (searchRare and isRare) || 
				(searchUncommon and isUncommon) || (searchCommon and isCommon) || (searchBasicLand and isBasicLand) || 	
				(searchSpecial and isSpecial)) and	finishedCards[name] == false and useBatchFile == false)	
				
				PutCardInFile card['colors'], card['types'], name, fileManager, finishedCards
			end
		end
	end
	
	# Put the cards that weren't found in batch file into an 'unknown' file
	if useBatchFile
		batchCards.each do |card, value|
			if value == true				
				batchCards[card] = false
				fileManager.unknownFile card				
			end
		end
	end

	fileManager.CloseFiles

#####



puts "Finished."