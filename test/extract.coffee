require "../appRequires"
assert = require "assert"

div = """<div class="t m0 x17 h8 y118 ff1 fs5 fc0 sc0 ls0 ws0">makers <span class="_ _7"> </span>and <span class="_ _7"> </span>deal <span class="_ _7"> </span>breakers: <span class="_ _7"> </span>analyses <span class="_ _7"> </span>of <span class="_ _7"> </span>assortativ<span class="_ _0"></span>e <span class="_ _7"> </span>mating <span class="_ _7"> </span>in </div>"""
divContent = """makers <span class="_ _7"> </span>and <span class="_ _7"> </span>deal <span class="_ _7"> </span>breakers: <span class="_ _7"> </span>analyses <span class="_ _7"> </span>of <span class="_ _7"> </span>assortativ<span class="_ _0"></span>e <span class="_ _7"> </span>mating <span class="_ _7"> </span>in """

describe 'removeOuterDivs', -> 
  it 'should only return divs that do not wrap around other divs', -> 
    assert.equal(util.removeOuterDivs("<div><div>something</div></div>"), "<div>something</div>")

describe 'simpleGetDivContent', -> 
  it 'should correctly extract the inner text of a div', -> 
    assert.equal(util.simpleGetDivContent(div), divContent)
  it 'should extract an empty string when there is no content', ->
    assert.equal(util.simpleGetDivContent("""<div class="something"></div>"""),"")
  it 'should extract a space when content is a space', ->
    assert.equal(util.simpleGetDivContent("""<div class="something"> </div>""")," ")    	
    
#TODO: Add test for simpleGetDivContent, that compares input and output of whole html file
#      Requires reading from files, maybe Mocha has something for it