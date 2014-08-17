# Clean mysql.
# The drop statement will fail if the user doesn't already exist,
# so it should be last here.

mysql -u root << EOF
DROP DATABASE IF EXISTS articlio;
DROP USER 'articlio'@'localhost';
EOF
