color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo -e "${color}Updating plato js source analysis for this app...${detail_color}"
echo -e "See the output at file://`pwd`/plato-out/index.html when done."
echo -e "${NC}"
plato -r -x "plato-out|hadasino-server|test" -d plato-out {,**/}*.js
