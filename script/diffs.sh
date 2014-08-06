#
# This file just lists useful diff tactics in the command-line
#
# Notes:
#
# The diff command and most others use an algorithm that results in either change 
# groups or columns, rather than a line by line comparison that is
# easy to pipe to a line difference comparison
#
# Sublime 3 issue on linux - doesn't stdin output, hence temp file is required.....
#

# The best workhorse linux command is diff and the best usage is:
diff 1.out 33.out -U0 --new-file # unified modern format; 
                                 # no context; 
                                 # missing file treated as empty file rather than raising an error

# Cool colorful diff output in sublime:
diff sentences-2014-08-02T22\:44\:36.044Z.out sentences-2014-08-02T19\:53\:31.234Z.out > diff.out; subl diff.out

# Summary of (primitive) amount of changes only
diff sentences-2014-08-02T22\:44\:36.044Z.out sentences-2014-08-02T19\:53\:31.234Z.out  | diffstat -C

# Different type of diff output, requires files are initially sorted - will not care about line order.., simpler output for missing lines.. but not that different otherwise
comm -3 <(sort 1.out) <(sort 2.out) > comm.out; subl comm.out

# Binary comparison yielding only whether files are binarily identical or not
cmp 1.out 2.out

#there's also | colordiff to get nice colors in the terminal

# There's also wdiff, but it doesn't discern new lines as changes:
wdiff 1.out 2.out -w"<old>" -x"</old>" -y"<new>" -z"<new>" > diff.out; subl diff.out

# Piping diff to wdiff -d works but does not provide directly logical results. 
# It can be used to intuitively make sense of what exactly line diffs may be
# In a partial way that produces some noise, but can "work"
diff 1.out 2.out -U0 | wdiff -d

# Oh, and to get bottom line stats of regular the diff command
diff 1.out 2.out -u | diffstat -C 
diff 1.out 2.out -u | diffstat -C -f4 
diff 1.out 2.out -u | diffstat -s     

# Check out http://stackoverflow.com/questions/25147328/diff-command-avoiding-monolithic-grouping-of-consecutive-differing-lines for anything useful

# Google's optimized algorithm (javascript, Java and other language versions all available):
https://code.google.com/p/google-diff-match-patch/