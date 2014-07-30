color='\e[1;34m'
detail_color='\e[1;30m'
NC='\e[0m' # No Color
echo -e "${color}"
echo "About to start with debug enabled"
echo "================================="
echo "Suggested use: make sure you added a 'debugger' statement in the desired place in the code, enter 'c' at the prompt to get going, "
echo "then enter 'repl' at the prompt to start a repl when it breaks on your 'debugger' statement in the code."
echo
echo -e "Debugger and repl reference:  "
echo -e "---------------------------------${detail_color}"
echo -e "For debugger help - enter 'help' "
echo -e "For repl help -     enter '.help'${color}"
echo -e "---------------------------------"
echo -e "Starting..."
echo -e ${NC}
authbind --deep nodemon --nodejs debug app.coffee

