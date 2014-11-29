select docName, count(*), sum(header like '%ntroduction%'), sum(header like '%onclusion%')
from articlio.headers 
where runID = 'ubuntu-2014-11-23T05:55:33.921Z' 
group by docName
having sum(header like '%ntroduction%') = 0 or sum(header like '%onclusion%') = 0