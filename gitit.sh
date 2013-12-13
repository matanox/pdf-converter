color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo -e ${color}
echo "Trying to stage and commit all changes"
echo -e ${detail_color}
git status
git add .
git add -u
git status
echo "Trying to commit with comment \"$1\""
echo -e ${color}
git commit -am "\"$1\""
echo
git status
echo -e ${NC}
