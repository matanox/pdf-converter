color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
./lint.sh; ./plato.sh; echo -e "\n${color}Running tests...${NC}"; mocha --recursive --check-leaks
