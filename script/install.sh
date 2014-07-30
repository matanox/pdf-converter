# Installation script for Ubuntu
color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo
echo -e "${color}I. installing npm dependencies${detail_color}"
echo
npm install
echo -e "${color}II.opening linux ports${detail_color}" 	
echo "Installing authbind if not already installed... this may generate some apt-get output"
sudo apt-get install authbind
./open-ports.sh
echo -e "${NC}"
