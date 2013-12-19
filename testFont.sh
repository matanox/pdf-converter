chars="abcd .,-:()[]'"
echo -e
echo -e "Creating png image using the supplied font file $1 and some interesting characters to test it..."
echo -e "The character sequence being tested is: $chars"
echo -e
fontimage --text "$chars" $1
