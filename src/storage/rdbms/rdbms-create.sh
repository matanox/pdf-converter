# get mysql ready

mysql -u root << EOF
CREATE USER 'articlio'@'localhost';
GRANT ALL PRIVILEGES ON * . * TO 'articlio'@'localhost';
CREATE DATABASE articlio;
EOF
