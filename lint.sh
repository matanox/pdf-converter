color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo -e "${color}Coffeelinting all coffeescript files...${detail_color}"
echo -e "See http://www.coffeelint.org/#usage for details"
echo -e "${NC}"
coffeelint {,**/}*.coffee
