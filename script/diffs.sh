#
# Sublime 3 issue on linux - doesn't stdin output, hence temp file is required.....
#

# Cool colorful diff output in sublime:
diff sentences-2014-08-02T22\:44\:36.044Z.out sentences-2014-08-02T19\:53\:31.234Z.out > diff.out; subl diff.out

# Summary of (primitive) amount of changes only
diff sentences-2014-08-02T22\:44\:36.044Z.out sentences-2014-08-02T19\:53\:31.234Z.out  | diffstat -C

# Different type of diff output, requires files are initially sorted - will not care about line order.., simpler output for missing lines.. but not that different otherwise
comm -3 <(sort 1.out) <(sort 2.out) > comm.out; subl comm.out

# Binary comparison yielding only whether files are binarily identical or not
cmp 1.out 2.out

