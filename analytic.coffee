exports.analytic = (tokens) ->

  #
  # Utility function for logging frequencies  
  # of values appearing in a certain named property 
  # appearing under a certain object included in a token.
  #
  # E.g. for calculating frequencies of styles.
  #
  # Parameters:
  #
  # objectsArray        - the array of tokens
  # filterKey, filterBy - condition to filter from the array by
  # property            - which property to get the frequency of its values
  # parentProperty      - the parent of that property in the token object
  #
  frequencies = (objectsArray, filterKey, filterBy, property, parentProperty) ->
    map = {}
    for object in objectsArray when object[filterKey] is filterBy
      for key, value of object[parentProperty] 
        if key is property 
          value = parseFloat(value)
          if map[value]?
            map[value] += 1
          else
            map[value] = 1

    array = []
    for key, val of map
      array.push({key, val})
    array.sort( (a, b) -> return parseFloat(b.val) - parseFloat(a.val) )

    #console.dir array[i] for i in [0..39] when array[i]?

  frequencies(tokens, 'metaType', 'regular', 'left', 'positionInfo')
  frequencies(tokens, 'metaType', 'regular', 'font-size', 'finalStyles')  

  util.timelog('Calculating word frequencies')
  wordFrequencies = {}
  for token in tokens when token.metaType is 'regular'
    # won't hurt filtering out punctuation as well
    word = token.text 
    if wordFrequencies[word]? 
      wordFrequencies[word] += 1
    else 
      wordFrequencies[word] = 1
  util.timelog('Calculating word frequencies')   

  util.timelog('Sorting frequencies')
  wordFrequenciesArray = []
  for word, frequency of wordFrequencies
    wordFrequenciesArray.push({word, frequency})
  wordFrequenciesArray.sort( (a, b) -> return parseInt(b.frequency) - parseInt(a.frequency) )
  util.timelog('Sorting frequencies')
  #console.dir wordFrequenciesArray[i] for i in [0..39]
