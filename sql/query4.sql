select docName, count(*), sum(header = 'Introduction') as introduction, sum(header = 'conclusion') as conclusion, sum(header = 'references') as 'references'
from articlio.headers 
where runID = 'ubuntu-2014-11-21T12:06:51.286Z' 
group by docName
having sum(header = 'Introduction') = 0


