select docName, count(*), sum(header like '%ntroduction%') as introduction
from articlio.headers 
where runID = 'ubuntu-2014-11-23T05:55:33.921Z' 
group by docName
having sum(header = 'references') = 0