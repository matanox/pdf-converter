color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo -e ${detail_color}
git status
git add .
git add -u
git status
echo -e ${color}
echo "trying to commit with comment \"$1\""
git commit -am \"1\"
