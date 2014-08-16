# clean mysql

mysql -u root << EOF
DROP USER articlio@localhost;
DROP DATABASE articlio;
EOF
