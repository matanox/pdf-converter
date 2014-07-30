# Create cloc listing for the code of the current directory, such that it can be processed with code
# similarly to CodeFlower, to visualize project's source weights
cloc . --csv --exclude-ext=js,sh --exclude-dir=node_modules,bootstrap3,logs,plato-out,old,recycle-bin,test,stylesheets --by-file --report-file=back-end-js.cloc
