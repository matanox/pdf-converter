#
# Some headers to be expected in an article
#

expected = 
[
  'Introduction',
  'Method',
  'Methodology'
  'Discussion',
  'General Discussion'
  'Results',
  'Conclusion',
  'References'
]

# derives uppercase variants
deriveUpperCase = (base) ->
  variants = []
  base.forEach((item) -> 
      variants.push item.toUpperCase()
    )
  return variants

# derives the variant where the first char is ommitted, making a better catch all for initial caps
deriveInitialCaps = (base) ->
  variants = []
  base.forEach((item) -> 
      variants.push item.substring(1)
    )
  return variants

expand = (expected) ->
  return expected.concat deriveUpperCase(expected), deriveInitialCaps(expected)

module.exports = expand(expected)
