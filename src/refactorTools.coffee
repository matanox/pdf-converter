logging  = require './util/logging' 

#
# Code refactor aiding function that examines all elements in an array,
# and returns the 'maximum' structure of an item of the array,
# thus simplifying some kinds of refactoring
#
exports.deriveStructure = (elements) ->

  iterate = (element, maxStructure) ->
    for key, val of element
      unless maxStructure[key]?
        switch typeof(val)
          when "object"
            maxStructure[key] = {}
            iterate(val, maxStructure[key])
          else
            maxStructure[key] = val

  maxStructure = {}
  for element in elements
    iterate(element, maxStructure)

  logging.cond 'token structure:', 'refactor'
  logging.cond maxStructure, 'refactor'

#
# Code refactor aiding function that examines all elements in an array,
# and returns the 'maximum' structure of an item of the array,
# thus simplifying some kinds of refactoring
#
exports.deriveStructureWithValues = (elements, variationLimit) ->

  unless variationLimit? # how many different values to include per attribute
    variationLimit = 5   # default to 5

  iterate = (element, maxStructure) ->
    for key, val of element
      switch typeof(val)
        when "object"
          unless maxStructure[key]?
            maxStructure[key] = {}
          iterate(val, maxStructure[key])
        else
          if maxStructure[key]?
            if maxStructure[key].length < variationLimit  # avoid saving more than N values per object attribute
              duplicateValue = false
              if maxStructure[key].indexOf(val) isnt -1 # avoid repeat values
                duplicateValue = true
              unless duplicateValue 
                maxStructure[key].push(val)
                maxStructure[key].sort()     # keep it sorted for viewer convenience 
          else
            maxStructure[key] = [val]        # create array and push current value as first item

  maxStructure = {}
  for element in elements
    iterate(element, maxStructure)

  logging.cond """token structure with possible values (up to #{variationLimit} unique values per object node):""", 'refactor'
  logging.cond maxStructure, 'refactor' 
