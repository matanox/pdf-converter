# get mysql ready

mysql -u root << EOF
CREATE USER 'articlio'@'localhost' IDENTIFIED BY 'articlio';
GRANT ALL PRIVILEGES ON * . * TO 'articlio'@'localhost';
CREATE DATABASE articlio;
EOF
